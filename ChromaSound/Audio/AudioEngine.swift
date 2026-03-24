import AVFoundation
import Accelerate
import Combine

/// Captures microphone audio and publishes [AudioFrame] via Combine.
/// Uses AVAudioEngine for capture and Apple's vDSP (Accelerate) for FFT —
/// hardware-accelerated on every iPhone.
final class AudioEngine: ObservableObject {

    // MARK: - Constants
    static let sampleRate:  Double = 44100
    static let fftSize:     Int    = 4096
    static let dbFloor:     Double = -80
    static let dbThreshold: Double = -50   // bins below this don't spawn objects

    // MARK: - Published output
    let framePublisher = PassthroughSubject<AudioFrame, Never>()

    // MARK: - Private state
    private let engine      = AVAudioEngine()
    private var fftSetup:     FFTSetup?
    private var hannWindow:   [Float]
    private var isRunning     = false

    // Settings read atomically each frame
    var currentBands:    BandDefinition = .build(count: 16)
    var sensitivity:     Double         = 1.0
    var subBandCount:    Int            = 4

    // MARK: - Init

    init() {
        let n = AudioEngine.fftSize
        // Pre-compute Hann window
        hannWindow = [Float](repeating: 0, count: n)
        vDSP_hann_window(&hannWindow, vDSP_Length(n), Int32(vDSP_HANN_NORM))

        // Create FFT setup for log2(fftSize) = 12
        let log2n = vDSP_Length(log2(Double(n)))
        fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(FFT_RADIX2))
    }

    deinit {
        stop()
        if let setup = fftSetup { vDSP_destroy_fftsetup(setup) }
    }

    // MARK: - Public API

    func requestPermissionAndStart(completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted { self?.start() }
                completion(granted)
            }
        }
    }

    func start() {
        guard !isRunning, let setup = fftSetup else { return }
        isRunning = true

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement,
                                      options: .allowBluetooth)
        try? audioSession.setActive(true)

        let inputNode = engine.inputNode
        let format    = inputNode.inputFormat(forBus: 0)
        let fftSize   = AudioEngine.fftSize

        inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(fftSize),
                             format: format) { [weak self] buffer, _ in
            self?.processBuffer(buffer, fftSetup: setup)
        }

        try? engine.start()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    // MARK: - FFT processing

    private func processBuffer(_ buffer: AVAudioPCMBuffer, fftSetup: FFTSetup) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let n = AudioEngine.fftSize
        guard Int(buffer.frameLength) >= n else { return }

        // Copy samples and apply Hann window
        var pcm = [Float](repeating: 0, count: n)
        cblas_scopy(Int32(n), channelData, 1, &pcm, 1)
        vDSP_vmul(pcm, 1, hannWindow, 1, &pcm, 1, vDSP_Length(n))

        // RMS
        var rmsFloat: Float = 0
        vDSP_rmsqv(pcm, 1, &rmsFloat, vDSP_Length(n))
        let rms = Double(min(rmsFloat, 1))

        // Split complex FFT
        var realPart = [Float](repeating: 0, count: n / 2)
        var imagPart = [Float](repeating: 0, count: n / 2)
        var splitComplex = DSPSplitComplex(realp: &realPart, imagp: &imagPart)

        pcm.withUnsafeBytes { rawPtr in
            let ptr = rawPtr.bindMemory(to: DSPComplex.self)
            vDSP_ctoz(ptr.baseAddress!, 2, &splitComplex, 1, vDSP_Length(n / 2))
        }

        let log2n = vDSP_Length(log2(Double(n)))
        vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))

        // Magnitudes — normalise by FFT size
        var magnitudesFloat = [Float](repeating: 0, count: n / 2)
        vDSP_zvabs(&splitComplex, 1, &magnitudesFloat, 1, vDSP_Length(n / 2))
        var scale = Float(1) / Float(n)
        vDSP_vsmul(magnitudesFloat, 1, &scale, &magnitudesFloat, 1, vDSP_Length(n / 2))

        // Normalise magnitudes to [0, 1]
        var maxMag: Float = 0
        vDSP_maxv(magnitudesFloat, 1, &maxMag, vDSP_Length(n / 2))
        if maxMag > 0 {
            var invMax = 1 / maxMag
            vDSP_vsmul(magnitudesFloat, 1, &invMax, &magnitudesFloat, 1, vDSP_Length(n / 2))
        }
        let magnitudes = magnitudesFloat.map { Double($0) }

        // dBFS per bin (apply sensitivity gain)
        let gain = sensitivity.clamped(to: 0.1...3.0)
        let dBLevels = magnitudes.map { mag -> Double in
            let raw = mag < 1e-10 ? AudioEngine.dbFloor : max(20 * log10(mag), AudioEngine.dbFloor)
            return (raw * gain).clamped(to: AudioEngine.dbFloor...0)
        }

        let bd = currentBands
        let nsb = subBandCount.clamped(to: 1...12)

        // Per-band peak bins
        var bandPeakBins  = [Int](repeating: -1, count: bd.count)
        var bandPeakDb    = [Double](repeating: AudioEngine.dbThreshold, count: bd.count)

        if rms > 0.002 {
            for bin in 1..<magnitudes.count {
                let hz   = Double(bin) * AudioEngine.sampleRate / Double(n)
                let band = bd.bandFor(hz: hz)
                guard band >= 0 else { continue }
                let db = dBLevels[bin]
                if db > bandPeakDb[band] {
                    bandPeakDb[band]   = db
                    bandPeakBins[band] = bin
                }
            }
        }

        // Sub-band energies per band
        let bandSubEnergies: [[Double]] = (0..<bd.count).map { band in
            let loHz  = bd.lowerHz[band]
            let hiHz  = bd.upperHz[band]
            let logLo = log10(loHz)
            let logHi = log10(hiHz)
            let step  = (logHi - logLo) / Double(nsb)
            let peakBin = bandPeakBins[band]
            let peakMag = peakBin >= 0 ? magnitudes[peakBin] : 0

            return (0..<nsb).map { sub in
                let subLo    = pow(10, logLo + Double(sub)     * step)
                let subHi    = pow(10, logLo + Double(sub + 1) * step)
                let subLoBin = max(1, Int(subLo * Double(n) / AudioEngine.sampleRate))
                let subHiBin = min(magnitudes.count - 1, Int(subHi * Double(n) / AudioEngine.sampleRate))
                guard subHiBin >= subLoBin else { return 0.0 }
                let slice = magnitudes[subLoBin...subHiBin]
                let avg   = slice.reduce(0, +) / Double(slice.count)
                return peakMag > 0 ? (avg / peakMag).clamped(to: 0...1) : 0
            }
        }

        let frame = AudioFrame(
            magnitudes:      magnitudes,
            rmsVolume:       rms,
            decibelLevels:   dBLevels,
            bandPeakBins:    bandPeakBins,
            bandSubEnergies: bandSubEnergies
        )

        DispatchQueue.main.async { [weak self] in
            self?.framePublisher.send(frame)
        }
    }
}
