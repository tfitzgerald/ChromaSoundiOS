import SwiftUI

// MARK: - Enums

enum ColorScheme: String, CaseIterable, Codable {
    case rainbow        = "Rainbow"
    case inverseRainbow = "Inverse Rainbow"
}

enum ObjectShape: String, CaseIterable, Codable {
    case circle = "Circle"
    case star   = "Star"
    case box2D  = "2D Box"
    case box3D  = "3D Box"
    case sphere = "Sphere"
}

// MARK: - Settings

/// All user-adjustable parameters. Stored as @Published in ViewModel.
struct AppSettings {
    var bandCount:      Int         = 16
    var lifetimeMs:     Double      = 500
    var circlesPerBand: Int         = 1
    var minRadiusPx:    Double      = 10
    var maxRadiusPx:    Double      = 160
    var placement:      Double      = 0.3
    var sensitivity:    Double      = 1.0
    var colorScheme:    ColorScheme = .rainbow
    var objectShape:    ObjectShape = .circle
    var subBands:       Int         = 4
    var bandColors:     [Int: Color] = [:]

    // Slider bounds
    static let minBands         = 2;    static let maxBands         = 24
    static let minLifetimeMs    = 100.0; static let maxLifetimeMs   = 2000.0
    static let minCirclesPerBand = 1;   static let maxCirclesPerBand = 5
    static let minRadiusFloor   = 5.0;  static let maxRadiusFloor   = 120.0
    static let minRadiusCeiling = 20.0; static let maxRadiusCeiling = 250.0
    static let minPlacement     = 0.0;  static let maxPlacement     = 1.0
    static let minSensitivity   = 0.1;  static let maxSensitivity   = 3.0
    static let minSubBands      = 1;    static let maxSubBands      = 12
}

// MARK: - FrequencyCircle

/// One rendered object on the canvas — corresponds to one active frequency band.
struct FrequencyCircle: Identifiable {
    let id            = UUID()
    let bandIndex:    Int
    let slotIndex:    Int
    let x:            Double        // normalised [0, 1]
    let y:            Double        // normalised [0, 1]
    let radiusPx:     Double
    let color:        Color
    let spawnDate:    Date
    let lifetimeMs:   Double
    let centreHz:     Double
    let decibelLevel: Double
    let subBandEnergies: [Double]   // [0, 1] per sub-band slice

    var lifeFraction: Double {
        let age = Date().timeIntervalSince(spawnDate) * 1000  // ms
        return max(0, 1 - age / lifetimeMs)
    }

    var isAlive: Bool {
        Date().timeIntervalSince(spawnDate) * 1000 < lifetimeMs
    }
}

// MARK: - AudioFrame

/// One analysed FFT frame from the audio engine.
struct AudioFrame {
    let magnitudes:      [Double]    // normalised [0, 1], length = FFT_SIZE/2
    let rmsVolume:       Double      // [0, 1]
    let decibelLevels:   [Double]    // dBFS per bin
    let bandPeakBins:    [Int]       // loudest bin per band, -1 if silent
    let bandSubEnergies: [[Double]]  // [band][subBand] normalised energy
}

// MARK: - BandDefinition

struct BandDefinition {
    let count:    Int
    let lowerHz:  [Double]
    let upperHz:  [Double]
    let centreHz: [Double]

    static let minHz: Double = 30
    static let maxHz: Double = 11_000

    static func build(count: Int) -> BandDefinition {
        let n      = max(2, min(count, 24))
        let logMin = log10(minHz)
        let logMax = log10(maxHz)
        let step   = (logMax - logMin) / Double(n)
        var lower  = [Double](repeating: 0, count: n)
        var upper  = [Double](repeating: 0, count: n)
        var centre = [Double](repeating: 0, count: n)
        for i in 0..<n {
            lower[i]  = pow(10, logMin + Double(i)       * step)
            upper[i]  = pow(10, logMin + Double(i + 1)   * step)
            centre[i] = pow(10, logMin + (Double(i) + 0.5) * step)
        }
        return BandDefinition(count: n, lowerHz: lower, upperHz: upper, centreHz: centre)
    }

    func bandFor(hz: Double) -> Int {
        guard hz >= BandDefinition.minHz, hz <= BandDefinition.maxHz else { return -1 }
        for i in 0..<count { if hz <= upperHz[i] { return i } }
        return count - 1
    }
}
