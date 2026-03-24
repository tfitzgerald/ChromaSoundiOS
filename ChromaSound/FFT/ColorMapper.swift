import SwiftUI

/// Maps frequency (Hz) and band index to a SwiftUI Color.
enum ColorMapper {

    static let minHz: Double = 30
    static let maxHz: Double = 11_000

    /// Return the color for a band, checking per-band overrides first.
    static func colorForBand(
        bandIndex: Int,
        hz:        Double,
        scheme:    ColorScheme,
        overrides: [Int: Color]
    ) -> Color {
        if let override = overrides[bandIndex] { return override.opacity(1) }
        return frequencyToColor(hz: hz, scheme: scheme)
    }

    /// Map a frequency to a fully-opaque Color using the given scheme.
    static func frequencyToColor(hz: Double, scheme: ColorScheme) -> Color {
        let logMin = log10(minHz)
        let logMax = log10(maxHz)
        let logHz  = log10(max(minHz, min(hz, maxHz)))
        let t      = ((logHz - logMin) / (logMax - logMin)).clamped(to: 0...1)
        let tMapped = scheme == .inverseRainbow ? 1 - t : t
        // Hue: violet (270°) → red (0°) across the full range
        let hue = (270 - tMapped * 270).truncatingRemainder(dividingBy: 360)
        return hsvToColor(hue: hue, saturation: 1, value: 1)
    }

    /// Convert HSV to SwiftUI Color (alpha always 1).
    static func hsvToColor(hue: Double, saturation: Double, value: Double) -> Color {
        let h = hue / 60
        let i = Int(h)
        let f = h - Double(i)
        let p = value * (1 - saturation)
        let q = value * (1 - saturation * f)
        let t = value * (1 - saturation * (1 - f))
        let (r, g, b): (Double, Double, Double)
        switch i % 6 {
        case 0: (r, g, b) = (value, t, p)
        case 1: (r, g, b) = (q, value, p)
        case 2: (r, g, b) = (p, value, t)
        case 3: (r, g, b) = (p, q, value)
        case 4: (r, g, b) = (t, p, value)
        default:(r, g, b) = (value, p, q)
        }
        return Color(red: r, green: g, blue: b)
    }

    /// Decompose a SwiftUI Color into [hue°, saturation, value].
    static func colorToHSV(_ color: Color) -> (h: Double, s: Double, v: Double) {
        let resolved = color.resolve(in: .init())
        let r = Double(resolved.red)
        let g = Double(resolved.green)
        let b = Double(resolved.blue)
        let mx = max(r, g, b)
        let mn = min(r, g, b)
        let delta = mx - mn
        let v = mx
        let s = mx == 0 ? 0.0 : delta / mx
        var h: Double = 0
        if delta > 0 {
            if mx == r      { h = 60 * (((g - b) / delta).truncatingRemainder(dividingBy: 6)) }
            else if mx == g { h = 60 * ((b - r) / delta + 2) }
            else            { h = 60 * ((r - g) / delta + 4) }
        }
        if h < 0 { h += 360 }
        return (h, s, v)
    }

    /// Convert a Color to a hex string like #FF6B00
    static func colorToHex(_ color: Color) -> String {
        let resolved = color.resolve(in: .init())
        let r = Int(resolved.red   * 255)
        let g = Int(resolved.green * 255)
        let b = Int(resolved.blue  * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
