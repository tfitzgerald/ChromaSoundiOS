import SwiftUI

private let bgColor = Color(red: 0.02, green: 0.02, blue: 0.03)
private let cardBg  = Color(red: 0.06, green: 0.06, blue: 0.10)
private let accentC = Color(red: 0.49, green: 0.44, blue: 1.0)
private let textC   = Color(red: 0.88, green: 0.87, blue: 0.97)
private let subtleC = Color(red: 0.35, green: 0.34, blue: 0.44)

struct BandColorView: View {
    @ObservedObject var vm: ChromaSoundViewModel
    let onClose: () -> Void

    @State private var activeBand: Int? = nil

    private var bands: BandDefinition {
        BandDefinition.build(count: vm.settings.bandCount)
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onClose) {
                        Text("← BACK")
                            .font(.system(size: 11, design: .monospaced)).tracking(2)
                            .foregroundColor(textC)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .overlay(Capsule().stroke(subtleC, lineWidth: 1))
                    }
                    Spacer()
                    Text("BAND COLOURS")
                        .font(.system(size: 18, design: .monospaced).weight(.black))
                        .foregroundColor(textC).tracking(3)
                    Spacer()
                    Button("RESET") {
                        var s = vm.settings
                        s.bandColors = [:]
                        vm.updateSettings(s)
                        activeBand = nil
                    }
                    .font(.system(size: 10, design: .monospaced)).tracking(2)
                    .foregroundColor(subtleC)
                }
                .padding(.top, 56).padding(.horizontal, 20).padding(.bottom, 12)

                Text("Tap a swatch to override. Leave at auto to follow the colour scheme.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(subtleC).multilineTextAlignment(.center)
                    .padding(.horizontal, 20).padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(0..<bands.count, id: \.self) { bandIdx in
                            bandRow(bandIdx: bandIdx)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Band row

    private func bandRow(bandIdx: Int) -> some View {
        let autoColor    = ColorMapper.frequencyToColor(hz: bands.centreHz[bandIdx], scheme: vm.settings.colorScheme)
        let activeColor  = vm.settings.bandColors[bandIdx] ?? autoColor
        let isOverridden = vm.settings.bandColors[bandIdx] != nil
        let isOpen       = activeBand == bandIdx

        return VStack(spacing: 0) {
            // Row header
            HStack {
                // Band number badge
                Text("\(bandIdx + 1)")
                    .font(.system(size: 12, design: .monospaced).weight(.bold))
                    .foregroundColor(accentC)
                    .frame(width: 32, height: 32)
                    .background(accentC.opacity(0.15), in: RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(formatHz(bands.lowerHz[bandIdx])) – \(formatHz(bands.upperHz[bandIdx]))")
                        .font(.system(size: 12, design: .monospaced)).foregroundColor(textC)
                    Text(isOverridden ? "CUSTOM" : "AUTO")
                        .font(.system(size: 9, design: .monospaced)).tracking(2)
                        .foregroundColor(isOverridden ? accentC : subtleC)
                }

                Spacer()

                // Swatch
                Circle()
                    .fill(activeColor)
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(isOpen ? Color.white : subtleC.opacity(0.5),
                                             lineWidth: isOpen ? 2 : 1))

                // Reset button
                if isOverridden {
                    Button("✕") {
                        var s = vm.settings
                        s.bandColors.removeValue(forKey: bandIdx)
                        vm.updateSettings(s)
                        if activeBand == bandIdx { activeBand = nil }
                    }
                    .font(.system(size: 14)).foregroundColor(subtleC)
                    .padding(.leading, 8)
                } else {
                    Spacer().frame(width: 30)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture { activeBand = activeBand == bandIdx ? nil : bandIdx }

            // Inline HSV picker
            if isOpen {
                HSVPickerView(
                    color: vm.settings.bandColors[bandIdx] ?? autoColor
                ) { newColor in
                    var s = vm.settings
                    s.bandColors[bandIdx] = newColor
                    vm.updateSettings(s)
                }
                .padding(.horizontal, 16).padding(.bottom, 16)
            }
        }
        .background(cardBg, in: RoundedRectangle(cornerRadius: 12))
    }

    private func formatHz(_ hz: Double) -> String {
        hz >= 1000 ? String(format: "%.1f kHz", hz/1000) : "\(Int(hz)) Hz"
    }
}

// MARK: - HSV Picker

struct HSVPickerView: View {
    let color:          Color
    let onColorChanged: (Color) -> Void

    @State private var hue:   Double
    @State private var sat:   Double
    @State private var val:   Double

    init(color: Color, onColorChanged: @escaping (Color) -> Void) {
        self.color          = color
        self.onColorChanged = onColorChanged
        let hsv = ColorMapper.colorToHSV(color)
        _hue = State(initialValue: hsv.h)
        _sat = State(initialValue: hsv.s)
        _val = State(initialValue: hsv.v)
    }

    private var pickedColor: Color { ColorMapper.hsvToColor(hue: hue, saturation: sat, value: val) }
    private var hueColor:    Color { ColorMapper.hsvToColor(hue: hue, saturation: 1, value: 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Hue bar
            Text("HUE").font(.system(size: 9, design: .monospaced)).foregroundColor(subtleC).tracking(2)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Rainbow bar
                    LinearGradient(colors: [
                        ColorMapper.hsvToColor(hue: 0, saturation: 1, value: 1),
                        ColorMapper.hsvToColor(hue: 60, saturation: 1, value: 1),
                        ColorMapper.hsvToColor(hue: 120, saturation: 1, value: 1),
                        ColorMapper.hsvToColor(hue: 180, saturation: 1, value: 1),
                        ColorMapper.hsvToColor(hue: 240, saturation: 1, value: 1),
                        ColorMapper.hsvToColor(hue: 300, saturation: 1, value: 1),
                        ColorMapper.hsvToColor(hue: 360, saturation: 1, value: 1)
                    ], startPoint: .leading, endPoint: .trailing)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Thumb
                    let thumbX = CGFloat(hue / 360) * geo.size.width
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 3, height: geo.size.height)
                        .cornerRadius(2)
                        .offset(x: thumbX - 1.5)
                }
                .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                    hue = (Double(v.location.x / geo.size.width) * 360).clamped(to: 0...360)
                    onColorChanged(pickedColor)
                })
            }
            .frame(height: 28)

            // SV square
            Text("SATURATION  ×  BRIGHTNESS")
                .font(.system(size: 9, design: .monospaced)).foregroundColor(subtleC).tracking(2)
            GeometryReader { geo in
                ZStack {
                    // Saturation: white → hue colour
                    LinearGradient(colors: [.white, hueColor],
                                   startPoint: .leading, endPoint: .trailing)
                    // Value: transparent → black
                    LinearGradient(colors: [.clear, .black],
                                   startPoint: .top, endPoint: .bottom)
                    // Crosshair
                    let tx = CGFloat(sat)   * geo.size.width
                    let ty = CGFloat(1-val) * geo.size.height
                    Circle().stroke(Color.white, lineWidth: 2.5).frame(width: 16, height: 16)
                        .offset(x: tx - geo.size.width/2, y: ty - geo.size.height/2)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                    sat = (Double(v.location.x / geo.size.width)).clamped(to: 0...1)
                    val = (1 - Double(v.location.y / geo.size.height)).clamped(to: 0...1)
                    onColorChanged(pickedColor)
                })
            }
            .frame(height: geo_svHeight())

            // Preview
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(pickedColor)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(subtleC.opacity(0.4), lineWidth: 1))
                VStack(alignment: .leading, spacing: 2) {
                    Text("SELECTED COLOUR")
                        .font(.system(size: 9, design: .monospaced)).foregroundColor(subtleC).tracking(2)
                    Text(ColorMapper.colorToHex(pickedColor))
                        .font(.system(size: 14, design: .monospaced).weight(.bold))
                        .foregroundColor(textC)
                }
                Spacer()
                Text("H \(Int(hue))°  S \(Int(sat*100))%  V \(Int(val*100))%")
                    .font(.system(size: 10, design: .monospaced)).foregroundColor(subtleC)
            }
        }
    }

    private func geo_svHeight() -> CGFloat { 130 }
}
