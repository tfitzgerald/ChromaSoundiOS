import SwiftUI

// MARK: - Sub-band gradient helper

/// Build a radial gradient from sub-band energies.
/// Inner ring = lowest frequency sub-band, outer = highest.
/// Energy 1.0 = full brightness, 0.0 = near-black.
func subBandGradient(
    color:           Color,
    alpha:           Double,
    subBandEnergies: [Double]
) -> RadialGradient {
    let n = max(subBandEnergies.count, 1)
    var stops: [Gradient.Stop] = []

    // White hot centre
    stops.append(.init(color: Color.white.opacity(alpha * 0.55), location: 0))

    // One stop per sub-band
    for i in 0..<n {
        let energy     = subBandEnergies[i]
        let brightness = 0.15 + energy * 0.85
        let adjusted   = color.adjustBrightness(brightness).opacity(alpha * (0.3 + energy * 0.65))
        let loc        = (Double(i) + 1) / Double(n + 1)
        stops.append(.init(color: adjusted, location: loc))
    }
    stops.append(.init(color: Color.clear, location: 1))

    return RadialGradient(stops: stops, center: .center, startRadius: 0, endRadius: 1)
}

// MARK: - Shape dispatcher

func drawShape(
    context:  inout GraphicsContext,
    circle:   FrequencyCircle,
    life:     Double,
    shape:    ObjectShape,
    angle:    Double,   // rotation angle in radians (for 3D shapes)
    canvasSize: CGSize
) {
    let cx    = circle.x * canvasSize.width
    let cy    = circle.y * canvasSize.height
    let r     = circle.radiusPx
    let alpha = life > 0.6 ? 1.0 : (life / 0.6).clamped(to: 0...1)

    switch shape {
    case .circle: drawCircleShape(&context, cx: cx, cy: cy, r: r, circle: circle, alpha: alpha)
    case .star:   drawStarShape(&context,   cx: cx, cy: cy, r: r, circle: circle, alpha: alpha)
    case .box2D:  drawBox2DShape(&context,  cx: cx, cy: cy, r: r, circle: circle, alpha: alpha)
    case .box3D:  drawBox3DShape(&context,  cx: cx, cy: cy, r: r, circle: circle, alpha: alpha, angle: angle)
    case .sphere: drawSphereShape(&context, cx: cx, cy: cy, r: r, circle: circle, alpha: alpha, angle: angle)
    }
}

// MARK: - Circle

private func drawCircleShape(
    _ ctx: inout GraphicsContext,
    cx: Double, cy: Double, r: Double,
    circle: FrequencyCircle, alpha: Double
) {
    let center = CGPoint(x: cx, y: cy)
    // Outer glow
    var glowCtx = ctx
    glowCtx.blendMode = .screen
    glowCtx.fill(
        Path(ellipseIn: CGRect(x: cx - r * 2.4, y: cy - r * 2.4, width: r * 4.8, height: r * 4.8)),
        with: .radialGradient(
            Gradient(colors: [circle.color.opacity(alpha * 0.22), .clear]),
            center: center, startRadius: 0, endRadius: r * 2.4
        )
    )
    // Core with sub-band shading
    var coreCtx = ctx
    coreCtx.blendMode = .screen
    coreCtx.fill(
        Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)),
        with: .radialGradient(
            subBandGradient(color: circle.color, alpha: alpha, subBandEnergies: circle.subBandEnergies),
            center: center, startRadius: 0, endRadius: r
        )
    )
}

// MARK: - Star

private func drawStarShape(
    _ ctx: inout GraphicsContext,
    cx: Double, cy: Double, r: Double,
    circle: FrequencyCircle, alpha: Double
) {
    let outerR = r
    let innerR = r * 0.42
    let points = 5
    var path   = Path()
    for i in 0..<(points * 2) {
        let ang    = Double(i) * .pi / Double(points) - .pi / 2
        let radius = i % 2 == 0 ? outerR : innerR
        let px     = cx + cos(ang) * radius
        let py     = cy + sin(ang) * radius
        if i == 0 { path.move(to: CGPoint(x: px, y: py)) }
        else      { path.addLine(to: CGPoint(x: px, y: py)) }
    }
    path.closeSubpath()
    let center = CGPoint(x: cx, y: cy)

    // Glow
    var glowCtx = ctx; glowCtx.blendMode = .screen
    glowCtx.fill(
        Path(ellipseIn: CGRect(x: cx - r*1.8, y: cy - r*1.8, width: r*3.6, height: r*3.6)),
        with: .radialGradient(
            Gradient(colors: [circle.color.opacity(alpha * 0.18), .clear]),
            center: center, startRadius: 0, endRadius: r * 1.8
        )
    )
    // Filled star
    var fillCtx = ctx; fillCtx.blendMode = .screen
    fillCtx.fill(path, with: .radialGradient(
        subBandGradient(color: circle.color, alpha: alpha, subBandEnergies: circle.subBandEnergies),
        center: center, startRadius: 0, endRadius: r
    ))
    // Outline
    var strokeCtx = ctx; strokeCtx.blendMode = .screen
    strokeCtx.stroke(path, with: .color(circle.color.opacity(alpha * 0.7)), lineWidth: 1.5)
}

// MARK: - 2D Box

private func drawBox2DShape(
    _ ctx: inout GraphicsContext,
    cx: Double, cy: Double, r: Double,
    circle: FrequencyCircle, alpha: Double
) {
    let half = r * 0.78
    let rect = CGRect(x: cx - half, y: cy - half, width: half * 2, height: half * 2)
    let center = CGPoint(x: cx, y: cy)

    // Glow
    var glowCtx = ctx; glowCtx.blendMode = .screen
    glowCtx.fill(
        Path(ellipseIn: CGRect(x: cx-r*1.8, y: cy-r*1.8, width: r*3.6, height: r*3.6)),
        with: .radialGradient(
            Gradient(colors: [circle.color.opacity(alpha * 0.18), .clear]),
            center: center, startRadius: 0, endRadius: r * 1.8
        )
    )
    // Fill
    var fillCtx = ctx; fillCtx.blendMode = .screen
    fillCtx.fill(Path(rect), with: .radialGradient(
        subBandGradient(color: circle.color, alpha: alpha, subBandEnergies: circle.subBandEnergies),
        center: center, startRadius: 0, endRadius: r
    ))
    // Outline
    var strokeCtx = ctx; strokeCtx.blendMode = .screen
    strokeCtx.stroke(Path(rect), with: .color(circle.color.opacity(alpha * 0.9)), lineWidth: 1.8)
}

// MARK: - 3D Box

private func drawBox3DShape(
    _ ctx: inout GraphicsContext,
    cx: Double, cy: Double, r: Double,
    circle: FrequencyCircle, alpha: Double, angle: Double
) {
    let s: Double = r * 0.65
    // 8 unit cube vertices
    let verts: [(x: Double, y: Double, z: Double)] = [
        (-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),
        (-1,-1, 1),(1,-1, 1),(1,1, 1),(-1,1, 1)
    ]
    let cosY = cos(angle); let sinY = sin(angle)
    let pitch = 0.52; let cosX = cos(pitch); let sinX = sin(pitch)

    // Project vertices
    let proj: [CGPoint] = verts.map { v in
        let rx  = v.x * cosY + v.z * sinY
        let ry2 = v.y * cosX - (-v.x * sinY + v.z * cosY) * sinX
        let rz2 = v.y * sinX + (-v.x * sinY + v.z * cosY) * cosX
        let sc  = 4.0 / (4.0 + rz2 + 2.0)
        return CGPoint(x: cx + rx * s * sc, y: cy + ry2 * s * sc)
    }

    // Glow bubble with sub-band shading
    var glowCtx = ctx; glowCtx.blendMode = .screen
    glowCtx.fill(
        Path(ellipseIn: CGRect(x: cx-r*2, y: cy-r*2, width: r*4, height: r*4)),
        with: .radialGradient(
            subBandGradient(color: circle.color, alpha: alpha * 0.4, subBandEnergies: circle.subBandEnergies),
            center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: r * 2
        )
    )

    // Edges
    let edges = [(0,1),(1,2),(2,3),(3,0),(4,5),(5,6),(6,7),(7,4),(0,4),(1,5),(2,6),(3,7)]
    for (a, b) in edges {
        let avgZ   = (verts[a].z + verts[b].z) / 2
        let bright = (0.4 + (avgZ + 1) * 0.3).clamped(to: 0.3...1.0)
        let subIdx = Int(((avgZ + 1) / 2 * Double(circle.subBandEnergies.count - 1)))
            .clamped(to: 0...max(0, circle.subBandEnergies.count - 1))
        let energy = circle.subBandEnergies.isEmpty ? 1.0 : circle.subBandEnergies[subIdx]
        var p = Path()
        p.move(to: proj[a]); p.addLine(to: proj[b])
        var edgeCtx = ctx; edgeCtx.blendMode = .screen
        edgeCtx.stroke(p,
            with: .color(circle.color.opacity(alpha * bright * (0.3 + energy * 0.7))),
            lineWidth: 2)
    }
    // Vertex dots
    for pt in proj {
        var dotCtx = ctx; dotCtx.blendMode = .screen
        dotCtx.fill(
            Path(ellipseIn: CGRect(x: pt.x-2.5, y: pt.y-2.5, width: 5, height: 5)),
            with: .color(circle.color.opacity(alpha * 0.7))
        )
    }
}

// MARK: - Sphere

private func drawSphereShape(
    _ ctx: inout GraphicsContext,
    cx: Double, cy: Double, r: Double,
    circle: FrequencyCircle, alpha: Double, angle: Double
) {
    let center = CGPoint(x: cx, y: cy)

    // Shaded disc — sub-band radial shading
    var discCtx = ctx; discCtx.blendMode = .screen
    discCtx.fill(
        Path(ellipseIn: CGRect(x: cx-r, y: cy-r, width: r*2, height: r*2)),
        with: .radialGradient(
            subBandGradient(color: circle.color, alpha: alpha, subBandEnergies: circle.subBandEnergies),
            center: center, startRadius: 0, endRadius: r
        )
    )
    // Outer glow
    var glowCtx = ctx; glowCtx.blendMode = .screen
    glowCtx.fill(
        Path(ellipseIn: CGRect(x: cx-r*2.2, y: cy-r*2.2, width: r*4.4, height: r*4.4)),
        with: .radialGradient(
            Gradient(colors: [circle.color.opacity(alpha * 0.2), .clear]),
            center: center, startRadius: 0, endRadius: r * 2.2
        )
    )

    // Latitude lines
    let latAngles = [-0.5, 0.0, 0.5]
    for (li, lat) in latAngles.enumerated() {
        let lineR  = r * cos(lat)
        let lineY  = cy + r * sin(lat)
        let subIdx = (Double(li) / 2 * Double(circle.subBandEnergies.count - 1))
        let energy = circle.subBandEnergies.isEmpty ? 1.0 : circle.subBandEnergies[Int(subIdx).clamped(to: 0...circle.subBandEnergies.count-1)]
        var path   = Path()
        var valid  = true
        for i in 0...64 {
            let a  = Double(i) / 64 * 2 * .pi + angle
            let px = cx + lineR * cos(a)
            let py = lineY + lineR * 0.12 * sin(a)
            if (px - cx) * (px - cx) + (py - cy) * (py - cy) > r * r * 1.02 {
                valid = false; break
            }
            if i == 0 { path.move(to: CGPoint(x: px, y: py)) }
            else      { path.addLine(to: CGPoint(x: px, y: py)) }
        }
        if valid {
            var lineCtx = ctx; lineCtx.blendMode = .screen
            lineCtx.stroke(path,
                with: .color(circle.color.opacity(alpha * (0.25 + energy * 0.5))),
                lineWidth: 1.2)
        }
    }

    // Longitude lines
    let lonOffsets = [0.0, .pi / 3, 2 * .pi / 3]
    for (li, lonOff) in lonOffsets.enumerated() {
        let lon    = angle + lonOff
        let subIdx = Int(Double(li) / 2 * Double(circle.subBandEnergies.count - 1))
            .clamped(to: 0...max(0, circle.subBandEnergies.count - 1))
        let energy = circle.subBandEnergies.isEmpty ? 1.0 : circle.subBandEnergies[subIdx]
        var path   = Path()
        var started = false
        for i in 0...64 {
            let t  = Double(i) / 64 * 2 * .pi
            let x3 = cos(t) * cos(lon)
            let z3 = cos(t) * sin(lon)
            let y3 = sin(t)
            if z3 < 0 { started = false; continue }
            let px = cx + x3 * r
            let py = cy + y3 * r
            if !started { path.move(to: CGPoint(x: px, y: py)); started = true }
            else        { path.addLine(to: CGPoint(x: px, y: py)) }
        }
        var lineCtx = ctx; lineCtx.blendMode = .screen
        lineCtx.stroke(path,
            with: .color(circle.color.opacity(alpha * (0.25 + energy * 0.5))),
            lineWidth: 1.2)
    }
}

// MARK: - Color extension

extension Color {
    /// Scale RGB channels by [brightness] keeping alpha.
    func adjustBrightness(_ brightness: Double) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return Color(red:   Double(r) * brightness,
                     green: Double(g) * brightness,
                     blue:  Double(b) * brightness)
            .opacity(Double(a))
    }
}
