import SwiftUI

// MARK: - Palette
private let bgColor  = Color(red: 0.02, green: 0.02, blue: 0.03)
private let accentC  = Color(red: 0.49, green: 0.44, blue: 1.0)
private let textC    = Color(red: 0.88, green: 0.87, blue: 0.97)
private let subtleC  = Color(red: 0.35, green: 0.34, blue: 0.44)

struct MainView: View {
    @ObservedObject var vm: ChromaSoundViewModel
    let onSettings: () -> Void

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            if vm.isRunning {
                RunningView(vm: vm, onSettings: onSettings)
            } else {
                IdleView(vm: vm)
            }
        }
        .alert("Microphone Access Denied",
               isPresented: $vm.permissionDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please grant microphone access in Settings to use ChromaSound.")
        }
    }
}

// MARK: - Idle

private struct IdleView: View {
    @ObservedObject var vm: ChromaSoundViewModel
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [accentC.opacity(0.8), .clear],
                        center: .center, startRadius: 0, endRadius: 60
                    ))
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulse ? 1.08 : 0.92)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                               value: pulse)
                    .onAppear { pulse = true }
            }
            Spacer().frame(height: 40)
            Text("CHROMA SOUND")
                .font(.system(.title2, design: .monospaced).weight(.black))
                .foregroundColor(textC)
                .tracking(6)
            Spacer().frame(height: 8)
            Text("30 Hz – 11 kHz  ·  sub-band shading")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(subtleC)
                .tracking(1)
            Spacer().frame(height: 56)
            Button {
                vm.startCapture()
            } label: {
                Text("TAP TO LISTEN")
                    .font(.system(size: 13, design: .monospaced).weight(.bold))
                    .tracking(3)
                    .foregroundColor(.white)
                    .frame(width: 220, height: 52)
                    .background(accentC, in: Capsule())
            }
            Spacer()
        }
    }
}

// MARK: - Running

private struct RunningView: View {
    @ObservedObject var vm: ChromaSoundViewModel
    let onSettings: () -> Void

    // Drives 3D shape rotation (one full revolution per 2 seconds)
    @State private var rotationAngle: Double = 0
    let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .top) {
            bgColor.ignoresSafeArea()

            // Band lane dividers
            BandLaneGrid(bandCount: vm.settings.bandCount)

            // Shape canvas
            ShapeCanvas(
                circles:   vm.circles,
                shape:     vm.settings.objectShape,
                angle:     rotationAngle
            )
            .ignoresSafeArea()

            // HUD
            VStack {
                HUDView(vm: vm, onSettings: onSettings)
                    .padding(.top, 52)
                    .padding(.horizontal, 20)
                Spacer()
                Button {
                    vm.stopCapture()
                } label: {
                    Text("■  STOP")
                        .font(.system(size: 12, design: .monospaced))
                        .tracking(3)
                        .foregroundColor(textC)
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .overlay(Capsule().stroke(subtleC, lineWidth: 1))
                }
                .padding(.bottom, 52)
            }
        }
        .onReceive(timer) { _ in
            rotationAngle += (2 * .pi) / (2 * 60)  // 1 rev per 2 seconds at 60 fps
            if rotationAngle > 2 * .pi { rotationAngle -= 2 * .pi }
        }
    }
}

// MARK: - Band lane grid

private struct BandLaneGrid: View {
    let bandCount: Int
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let laneW = size.width / Double(bandCount)
                for i in 1..<bandCount {
                    let x = Double(i) * laneW
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: size.height))
                    ctx.stroke(p, with: .color(.white.opacity(0.04)), lineWidth: 1)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Shape canvas

private struct ShapeCanvas: View {
    let circles: [FrequencyCircle]
    let shape:   ObjectShape
    let angle:   Double

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                for circle in circles {
                    let life = circle.lifeFraction
                    if life > 0 {
                        var c = circle
                        drawShape(context: &ctx, circle: c, life: life,
                                  shape: shape, angle: angle, canvasSize: size)
                    }
                }
            }
        }
    }
}

// MARK: - HUD

private struct HUDView: View {
    @ObservedObject var vm: ChromaSoundViewModel
    let onSettings: () -> Void
    @State private var liveBlink = false

    var body: some View {
        HStack(alignment: .center) {
            // Left: live dot + band count
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red.opacity(liveBlink ? 1 : 0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                                   value: liveBlink)
                        .onAppear { liveBlink = true }
                    Text("LIVE")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(subtleC).tracking(2)
                }
                Text("\(vm.activeCount) / \(vm.settings.bandCount) bands")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(textC)
            }

            Spacer()

            // Centre: volume bar
            VStack(spacing: 4) {
                Text("VOL")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(subtleC).tracking(2)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(subtleC.opacity(0.25))
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color(red:0.26,green:0.9,blue:0.96),
                                         accentC,
                                         Color(red:1,green:0.42,blue:0.42)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: geo.size.width * vm.rmsVolume)
                    }
                }
                .frame(width: 80, height: 6)
            }

            Spacer()

            // Right: peak + settings
            VStack(alignment: .trailing, spacing: 2) {
                Button(action: onSettings) {
                    Text("⚙")
                        .font(.system(size: 18))
                        .foregroundColor(subtleC)
                }
                Text(vm.peakHz)
                    .font(.system(size: 13, design: .monospaced).weight(.bold))
                    .foregroundColor(textC)
                Text(vm.peakDb)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(subtleC)
            }
        }
    }
}
