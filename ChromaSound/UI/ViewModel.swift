import SwiftUI
import Combine

/// Central state holder. Drives the entire UI.
final class ChromaSoundViewModel: ObservableObject {

    // MARK: - Published state
    @Published var settings        = AppSettings()
    @Published var circles:        [FrequencyCircle] = []
    @Published var rmsVolume:      Double = 0
    @Published var activeCount:    Int    = 0
    @Published var peakHz:         String = "—"
    @Published var peakDb:         String = "—"
    @Published var isRunning:      Bool   = false
    @Published var permissionDenied = false

    // MARK: - Private
    private let audioEngine = AudioEngine()
    private var cancellables = Set<AnyCancellable>()

    // [band][slot] → circle or nil
    private var bandSlots: [[FrequencyCircle?]] = []

    // MARK: - Init
    init() {
        rebuildSlots()
        audioEngine.framePublisher
            .sink { [weak self] frame in self?.processFrame(frame) }
            .store(in: &cancellables)
    }

    // MARK: - Public API

    func startCapture() {
        audioEngine.currentBands = BandDefinition.build(count: settings.bandCount)
        audioEngine.sensitivity  = settings.sensitivity
        audioEngine.subBandCount = settings.subBands
        audioEngine.requestPermissionAndStart { [weak self] granted in
            guard let self else { return }
            if granted { self.isRunning = true }
            else       { self.permissionDenied = true }
        }
    }

    func stopCapture() {
        audioEngine.stop()
        isRunning = false
        circles   = []
        bandSlots = []
        rebuildSlots()
    }

    func updateSettings(_ new: AppSettings) {
        settings = new
        audioEngine.currentBands = BandDefinition.build(count: new.bandCount)
        audioEngine.sensitivity  = new.sensitivity
        audioEngine.subBandCount = new.subBands
        rebuildSlots()
    }

    // MARK: - Helpers

    private func rebuildSlots() {
        let bc  = settings.bandCount
        let cpb = settings.circlesPerBand
        bandSlots = Array(repeating: Array(repeating: nil, count: cpb), count: bc)
    }

    // MARK: - Frame processing

    private func processFrame(_ frame: AudioFrame) {
        let now = Date()
        let bd  = BandDefinition.build(count: settings.bandCount)

        // Resize if settings changed
        if bandSlots.count != bd.count || (bandSlots.first?.count ?? 0) != settings.circlesPerBand {
            rebuildSlots()
        }

        // Expire dead circles
        for b in 0..<bd.count {
            for s in 0..<settings.circlesPerBand {
                if let c = bandSlots[b][s], !c.isAlive { bandSlots[b][s] = nil }
            }
        }

        // Spawn new circles from peak bins
        for band in 0..<min(bd.count, frame.bandPeakBins.count) {
            let peakBin = frame.bandPeakBins[band]
            guard peakBin >= 0 else { continue }

            let db       = band < frame.decibelLevels.count ? frame.decibelLevels[peakBin] : AudioEngine.dbFloor
            let centreHz = bd.centreHz[band]

            // Find oldest slot
            let targetSlot = (0..<settings.circlesPerBand).min(by: {
                let a = bandSlots[band][$0]?.lifeFraction ?? -1
                let b = bandSlots[band][$1]?.lifeFraction ?? -1
                return a < b
            }) ?? 0

            let x = computeX(band: band, bandCount: bd.count, placement: settings.placement)
            let y = computeY(placement: settings.placement)

            let subEnergies = band < frame.bandSubEnergies.count
                ? frame.bandSubEnergies[band]
                : Array(repeating: 1.0, count: settings.subBands)

            let color = ColorMapper.colorForBand(
                bandIndex: band,
                hz:        centreHz,
                scheme:    settings.colorScheme,
                overrides: settings.bandColors
            )

            bandSlots[band][targetSlot] = FrequencyCircle(
                bandIndex:       band,
                slotIndex:       targetSlot,
                x:               x,
                y:               y,
                radiusPx:        dbToRadius(db),
                color:           color,
                spawnDate:       now,
                lifetimeMs:      settings.lifetimeMs,
                centreHz:        centreHz,
                decibelLevel:    db,
                subBandEnergies: subEnergies
            )
        }

        let alive = bandSlots.flatMap { $0 }.compactMap { $0 }

        // HUD
        let loudest = alive.max(by: { $0.decibelLevel < $1.decibelLevel })
        let pHz = loudest.map { hz in
            hz.centreHz >= 1000
                ? String(format: "%.1f kHz", hz.centreHz / 1000)
                : String(format: "%d Hz", Int(hz.centreHz))
        } ?? "—"
        let pDb = loudest.map { String(format: "%.1f dB", $0.decibelLevel) } ?? "—"

        circles     = alive
        rmsVolume   = frame.rmsVolume
        activeCount = alive.count
        peakHz      = pHz
        peakDb      = pDb
    }

    // MARK: - Position helpers

    private func dbToRadius(_ db: Double) -> Double {
        let range      = -AudioEngine.dbThreshold
        let normalized = (db - AudioEngine.dbThreshold) / range
        return settings.minRadiusPx + normalized.clamped(to: 0...1) *
               (settings.maxRadiusPx - settings.minRadiusPx)
    }

    private func computeX(band: Int, bandCount: Int, placement: Double) -> Double {
        let centre    = (Double(band) + 0.5) / Double(bandCount)
        let halfBand  = 0.5 / Double(bandCount)
        let maxOffset = halfBand + placement * (0.5 - halfBand)
        let jitter    = Double.random(in: -1...1) * maxOffset * placement
        return (centre + jitter).clamped(to: 0.02...0.98)
    }

    private func computeY(placement: Double) -> Double {
        let maxOffset = placement * 0.45
        let jitter    = Double.random(in: -1...1) * maxOffset
        return (0.5 + jitter).clamped(to: 0.05...0.95)
    }
}
