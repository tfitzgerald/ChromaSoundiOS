import SwiftUI

private let bgColor  = Color(red: 0.02, green: 0.02, blue: 0.03)
private let cardBg   = Color(red: 0.06, green: 0.06, blue: 0.10)
private let accentC  = Color(red: 0.49, green: 0.44, blue: 1.0)
private let textC    = Color(red: 0.88, green: 0.87, blue: 0.97)
private let subtleC  = Color(red: 0.35, green: 0.34, blue: 0.44)

struct SettingsView: View {
    @ObservedObject var vm: ChromaSoundViewModel
    let onClose:          () -> Void
    let onOpenBandColors: () -> Void

    // Local mirrors for all sliders
    @State private var bandCount:      Double
    @State private var lifetimeMs:     Double
    @State private var circlesPerBand: Double
    @State private var minRadius:      Double
    @State private var maxRadius:      Double
    @State private var placement:      Double
    @State private var sensitivity:    Double
    @State private var subBands:       Double
    @State private var colorScheme:    ColorScheme
    @State private var objectShape:    ObjectShape

    init(vm: ChromaSoundViewModel, onClose: @escaping () -> Void, onOpenBandColors: @escaping () -> Void) {
        self.vm = vm
        self.onClose = onClose
        self.onOpenBandColors = onOpenBandColors
        let s = vm.settings
        _bandCount      = State(initialValue: Double(s.bandCount))
        _lifetimeMs     = State(initialValue: s.lifetimeMs)
        _circlesPerBand = State(initialValue: Double(s.circlesPerBand))
        _minRadius      = State(initialValue: s.minRadiusPx)
        _maxRadius      = State(initialValue: s.maxRadiusPx)
        _placement      = State(initialValue: s.placement)
        _sensitivity    = State(initialValue: s.sensitivity)
        _subBands       = State(initialValue: Double(s.subBands))
        _colorScheme    = State(initialValue: s.colorScheme)
        _objectShape    = State(initialValue: s.objectShape)
    }

    private func emit() {
        var s = vm.settings
        s.bandCount      = Int(bandCount)
        s.lifetimeMs     = lifetimeMs
        s.circlesPerBand = Int(circlesPerBand)
        s.minRadiusPx    = minRadius
        s.maxRadiusPx    = max(maxRadius, minRadius + 10)
        s.placement      = placement
        s.sensitivity    = sensitivity
        s.subBands       = Int(subBands)
        s.colorScheme    = colorScheme
        s.objectShape    = objectShape
        vm.updateSettings(s)
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    // Header
                    headerRow

                    // Sliders
                    settingCard(label: "FREQUENCY BANDS", subLabel: "30 Hz – 11 kHz",
                                value: "\(Int(bandCount))", unit: "bands") {
                        styledSlider(value: $bandCount,
                                     range: Double(AppSettings.minBands)...Double(AppSettings.maxBands),
                                     step: 1) { emit() }
                        sliderLabels("\(AppSettings.minBands)", "\(AppSettings.maxBands)")
                    }

                    settingCard(label: "CIRCLE LIFETIME", subLabel: "How long each object stays visible",
                                value: formatMs(lifetimeMs), unit: "") {
                        styledSlider(value: $lifetimeMs,
                                     range: AppSettings.minLifetimeMs...AppSettings.maxLifetimeMs,
                                     step: 100) { emit() }
                        sliderLabels(formatMs(AppSettings.minLifetimeMs), formatMs(AppSettings.maxLifetimeMs))
                    }

                    settingCard(label: "OBJECTS PER BAND", subLabel: "Max simultaneous objects per band",
                                value: "\(Int(circlesPerBand))",
                                unit: Int(circlesPerBand) == 1 ? "object" : "objects") {
                        styledSlider(value: $circlesPerBand,
                                     range: Double(AppSettings.minCirclesPerBand)...Double(AppSettings.maxCirclesPerBand),
                                     step: 1) { emit() }
                        sliderLabels("\(AppSettings.minCirclesPerBand)", "\(AppSettings.maxCirclesPerBand)")
                    }

                    settingCard(label: "MINIMUM SIZE", subLabel: "Radius at quietest detected level",
                                value: "\(Int(minRadius))", unit: "pt") {
                        styledSlider(value: $minRadius,
                                     range: AppSettings.minRadiusFloor...AppSettings.maxRadiusFloor) {
                            if maxRadius < minRadius + 10 { maxRadius = minRadius + 10 }
                            emit()
                        }
                        sliderLabels("\(Int(AppSettings.minRadiusFloor)) pt", "\(Int(AppSettings.maxRadiusFloor)) pt")
                    }

                    settingCard(label: "MAXIMUM SIZE", subLabel: "Radius at loudest detected level",
                                value: "\(Int(maxRadius))", unit: "pt") {
                        styledSlider(value: $maxRadius,
                                     range: AppSettings.minRadiusCeiling...AppSettings.maxRadiusCeiling) {
                            maxRadius = max(maxRadius, minRadius + 10); emit()
                        }
                        sliderLabels("\(Int(AppSettings.minRadiusCeiling)) pt", "\(Int(AppSettings.maxRadiusCeiling)) pt")
                    }

                    settingCard(label: "PLACEMENT", subLabel: "How randomly objects scatter from their band column",
                                value: placementLabel(placement), unit: "") {
                        styledSlider(value: $placement,
                                     range: AppSettings.minPlacement...AppSettings.maxPlacement) { emit() }
                        sliderLabels("Grid-locked", "Full random")
                    }

                    settingCard(label: "MIC SENSITIVITY", subLabel: "Amplify or reduce response to audio",
                                value: "×\(String(format: "%.1f", sensitivity))", unit: "") {
                        styledSlider(value: $sensitivity,
                                     range: AppSettings.minSensitivity...AppSettings.maxSensitivity) { emit() }
                        sliderLabels("×\(String(format: "%.1f", AppSettings.minSensitivity)) low",
                                     "×\(String(format: "%.1f", AppSettings.maxSensitivity)) high")
                    }

                    settingCard(label: "SUB-BAND SHADING",
                                subLabel: "Radial shading rings inside each object (1 = solid)",
                                value: Int(subBands) == 1 ? "Off" : "\(Int(subBands))",
                                unit: Int(subBands) == 1 ? "" : "rings") {
                        styledSlider(value: $subBands,
                                     range: Double(AppSettings.minSubBands)...Double(AppSettings.maxSubBands),
                                     step: 1) { emit() }
                        sliderLabels("Off (1)", "\(AppSettings.maxSubBands) rings")
                    }

                    // Color scheme toggle
                    colorSchemeCard

                    // Object shape selector
                    shapeCard

                    // Band colours navigation
                    bandColorsRow

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Sub-views

    private var headerRow: some View {
        HStack {
            Button(action: onClose) {
                Text("← BACK")
                    .font(.system(size: 11, design: .monospaced))
                    .tracking(2).foregroundColor(textC)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .overlay(Capsule().stroke(subtleC, lineWidth: 1))
            }
            Spacer()
            Text("SETTINGS")
                .font(.system(size: 18, design: .monospaced).weight(.black))
                .foregroundColor(textC).tracking(4)
            Spacer()
            Spacer().frame(width: 80)
        }
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    private var colorSchemeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("COLOR SCHEME", sub: "Hue order across frequency bands")
            HStack(spacing: 12) {
                ForEach(ColorScheme.allCases, id: \.self) { scheme in
                    let selected = colorScheme == scheme
                    let gradient = scheme == .rainbow
                        ? [Color.purple, Color.blue, Color.cyan, Color.green, Color.yellow, Color.red]
                        : [Color.red, Color.yellow, Color.green, Color.cyan, Color.blue, Color.purple]
                    VStack(spacing: 8) {
                        LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing)
                            .frame(height: 10).clipShape(Capsule())
                        Text(scheme.rawValue.uppercased())
                            .font(.system(size: 10, design: .monospaced).weight(.bold))
                            .foregroundColor(selected ? accentC : textC).tracking(1)
                        if selected {
                            Text("✓ ACTIVE").font(.system(size: 9, design: .monospaced))
                                .foregroundColor(accentC)
                        }
                    }
                    .padding(12)
                    .background(selected ? accentC.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(selected ? accentC : subtleC.opacity(0.3),
                                lineWidth: selected ? 2 : 1))
                    .onTapGesture { colorScheme = scheme; emit() }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
    }

    private var shapeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("OBJECT SHAPE", sub: "Shape used to represent each frequency band")
            let shapes = ObjectShape.allCases
            // Row 1: Circle, Star, 2D Box
            HStack(spacing: 10) {
                ForEach(shapes.prefix(3), id: \.self) { s in shapeButton(s) }
            }
            // Row 2: 3D Box, Sphere
            HStack(spacing: 10) {
                ForEach(shapes.suffix(2), id: \.self) { s in shapeButton(s) }
                Spacer().frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
    }

    private func shapeButton(_ s: ObjectShape) -> some View {
        let selected = objectShape == s
        let emojis: [ObjectShape: String] = [.circle:"●", .star:"★", .box2D:"■", .box3D:"⬡", .sphere:"◉"]
        let rotating = s == .box3D || s == .sphere
        return VStack(spacing: 6) {
            Text(emojis[s] ?? "●").font(.system(size: 26))
                .foregroundColor(selected ? accentC : textC)
            Text(s.rawValue.uppercased())
                .font(.system(size: 10, design: .monospaced).weight(.bold))
                .foregroundColor(selected ? accentC : textC).tracking(1)
                .multilineTextAlignment(.center)
            if rotating {
                Text("rotating").font(.system(size: 9, design: .monospaced)).foregroundColor(subtleC)
            }
            if selected { Text("✓").font(.system(size: 10, design: .monospaced)).foregroundColor(accentC) }
        }
        .padding(.vertical, 14).padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(selected ? accentC.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(selected ? accentC : subtleC.opacity(0.3), lineWidth: selected ? 2 : 1))
        .onTapGesture { objectShape = s; emit() }
    }

    private var bandColorsRow: some View {
        let count = vm.settings.bandColors.count
        return HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("BAND COLOURS")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(subtleC).tracking(3)
                Text(count == 0 ? "Using colour scheme for all bands"
                                : "\(count) band\(count == 1 ? "" : "s") with custom colour")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(textC)
            }
            Spacer()
            if count > 0 {
                HStack(spacing: 4) {
                    ForEach(Array(vm.settings.bandColors.values.prefix(6)), id: \.self) { col in
                        Circle().fill(col).frame(width: 18, height: 18)
                    }
                }
            }
            Text("→").font(.system(size: 18, design: .monospaced)).foregroundColor(accentC)
        }
        .padding(20)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
        .onTapGesture { onOpenBandColors() }
    }

    // MARK: - Reusable components

    private func settingCard<Content: View>(
        label: String, subLabel: String, value: String, unit: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(label).font(.system(size: 10, design: .monospaced))
                        .foregroundColor(subtleC).tracking(3)
                    Text(subLabel).font(.system(size: 11, design: .monospaced))
                        .foregroundColor(textC)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(value).font(.system(size: 38, design: .monospaced).weight(.black))
                        .foregroundColor(accentC).lineLimit(1)
                    if !unit.isEmpty {
                        Text(unit).font(.system(size: 10, design: .monospaced))
                            .foregroundColor(subtleC).tracking(2)
                    }
                }
            }
            content()
        }
        .padding(20)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 16))
    }

    private func styledSlider(value: Binding<Double>, range: ClosedRange<Double>,
                               step: Double? = nil, onChange: @escaping () -> Void) -> some View {
        Slider(value: value, in: range, step: step ?? (range.upperBound - range.lowerBound) / 200)
            .tint(accentC)
            .onChange(of: value.wrappedValue) { _ in onChange() }
    }

    private func sliderLabels(_ min: String, _ max: String) -> some View {
        HStack {
            Text(min).font(.system(size: 11, design: .monospaced)).foregroundColor(subtleC)
            Spacer()
            Text(max).font(.system(size: 11, design: .monospaced)).foregroundColor(subtleC)
        }
    }

    private func cardTitle(_ title: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.system(size: 10, design: .monospaced))
                .foregroundColor(subtleC).tracking(3)
            Text(sub).font(.system(size: 11, design: .monospaced)).foregroundColor(textC)
        }
    }

    // MARK: - Formatters

    private func formatMs(_ ms: Double) -> String {
        ms >= 1000 ? String(format: "%.1f s", ms / 1000) : "\(Int(ms)) ms"
    }

    private func placementLabel(_ v: Double) -> String {
        switch v {
        case ..<0.15: return "Grid"
        case ..<0.40: return "Slight"
        case ..<0.65: return "Medium"
        case ..<0.85: return "High"
        default:      return "Full"
        }
    }
}
