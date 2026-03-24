import SwiftUI

// MARK: - Palette

private let bgColor  = Color(red: 0.02, green: 0.02, blue: 0.03)
private let cardBg   = Color(red: 0.06, green: 0.06, blue: 0.10)
private let accentC  = Color(red: 0.49, green: 0.44, blue: 1.0)
private let textC    = Color(red: 0.88, green: 0.87, blue: 0.97)
private let subtleC  = Color(red: 0.35, green: 0.34, blue: 0.44)
private let tipGreen = Color(red: 0.0,  green: 0.8,  blue: 0.47)

// MARK: - Data model

private struct HelpItem {
    let emoji:       String
    let title:       String
    let range:       String
    let defaultVal:  String
    let description: String
    let tip:         String

    init(_ emoji: String, _ title: String,
         range: String = "", defaultVal: String = "",
         _ description: String, tip: String = "") {
        self.emoji       = emoji
        self.title       = title
        self.range       = range
        self.defaultVal  = defaultVal
        self.description = description
        self.tip         = tip
    }
}

private struct HelpSection {
    let heading: String
    let intro:   String
    let items:   [HelpItem]

    init(_ heading: String, intro: String = "", _ items: [HelpItem]) {
        self.heading = heading
        self.intro   = intro
        self.items   = items
    }
}

// MARK: - All help content

private let helpSections: [HelpSection] = [

    HelpSection("How ChromaSound Works",
        intro: "ChromaSound listens through your microphone, splits the sound into frequency bands, " +
               "and draws a coloured shape for each band that is active. The louder and more complex " +
               "the sound, the more shapes appear and the larger they grow.",
        [
            HelpItem("🎤", "Microphone Input",
                "ChromaSound captures raw audio at 44,100 samples per second. Each chunk of 4,096 " +
                "samples is processed in one frame (about 93 ms). No audio is ever recorded or saved " +
                "— everything happens in memory in real time.",
                tip: "Point your phone toward a speaker or instrument for the best visual response."
            ),
            HelpItem("📊", "FFT Analysis",
                "A Fast Fourier Transform (FFT) converts the raw audio into a spectrum — a measurement " +
                "of how much energy is present at each frequency. ChromaSound uses Apple's Accelerate " +
                "framework (vDSP) for hardware-accelerated FFT on every iPhone.",
                tip: "Music with a wide frequency range (bass, mids, and treble) will produce the " +
                     "most varied and colourful display."
            )
        ]
    ),

    HelpSection("Frequency & Timing", [
        HelpItem("🎼", "Frequency Bands",
            range: "2 – 24", defaultVal: "16",
            "Divides the audible range (30 Hz to 11 kHz) into this many bands. More bands means finer " +
            "frequency detail — each band covers a narrower range of frequencies and triggers its own " +
            "independent shape. Bands are spaced logarithmically, matching how human hearing works.",
            tip: "16 bands is a good balance. Try 8 for a bold look with larger shapes, or 24 for " +
                 "very detailed frequency analysis."
        ),
        HelpItem("⏱", "Circle Lifetime",
            range: "100 ms – 2000 ms", defaultVal: "500 ms",
            "How long each shape stays on screen before it fades out completely. Short lifetimes make " +
            "the display react very quickly to sound — shapes appear and disappear almost instantly. " +
            "Long lifetimes let shapes linger, creating a denser, more layered display.",
            tip: "For music with a fast beat, try 300–400 ms. For slow ambient sound, 800–1200 ms " +
                 "creates a beautiful lingering effect."
        ),
        HelpItem("🔢", "Objects Per Band",
            range: "1 – 5", defaultVal: "1",
            "The maximum number of shapes that can be shown simultaneously for each frequency band. " +
            "At 1, each band shows at most one shape at a time and new sound simply refreshes it. " +
            "At higher values, multiple shapes can stack up per band while older ones fade out.",
            tip: "Values of 2 or 3 add depth and layering. Values of 4–5 can be very dense — " +
                 "best with fewer frequency bands."
        )
    ]),

    HelpSection("Size & Position", [
        HelpItem("🔵", "Minimum Size",
            range: "5 – 120 pt", defaultVal: "10 pt",
            "The radius of a shape when the sound in that band is just barely above the detection " +
            "threshold. Very quiet sounds produce shapes close to this size.",
            tip: "Increase this if shapes feel too small to see clearly in a quiet environment."
        ),
        HelpItem("⭕", "Maximum Size",
            range: "20 – 250 pt", defaultVal: "160 pt",
            "The radius of a shape when the sound in that band is at its loudest detectable level. " +
            "A wide gap between minimum and maximum size makes the shapes very responsive to volume " +
            "— loud sounds produce dramatically larger shapes.",
            tip: "Try Min=20, Max=200 for very expressive size variation that reacts dramatically " +
                 "to loud sounds."
        ),
        HelpItem("🎲", "Circle Placement",
            range: "Grid-locked → Full random", defaultVal: "0.3 (Slight)",
            "Controls how randomly shapes scatter from their band's centre column. At zero " +
            "(Grid-locked), every shape for a given band appears in the same vertical column — " +
            "very ordered and structured. As you increase it, shapes scatter both left-right " +
            "and up-down, spreading across the whole screen at maximum.",
            tip: "Grid-locked looks great with the 3D Box shape. Full Random with Circles " +
                 "creates a galaxy-like scattered effect."
        )
    ]),

    HelpSection("Audio Sensitivity", [
        HelpItem("🎚", "Mic Sensitivity",
            range: "×0.1 – ×3.0", defaultVal: "×1.0",
            "A multiplier applied to the measured sound level before comparing it to the detection " +
            "threshold. At ×1.0 nothing changes. Increasing sensitivity (×2.0, ×3.0) makes quiet " +
            "sounds trigger and grow shapes they otherwise would not — useful in quiet environments. " +
            "Reducing sensitivity (×0.5, ×0.1) means only loud sounds produce shapes.",
            tip: "If you are in a quiet room and few shapes appear, try ×2.0 or ×3.0. If shapes " +
                 "are constantly at maximum size, try ×0.5."
        )
    ]),

    HelpSection("Shape",
        intro: "Choose the visual shape used to represent each active frequency band. " +
               "All shapes use the same sub-band radial shading system.",
        [
            HelpItem("●", "Circle",
                defaultVal: "Default",
                "A glowing disc with a radial gradient from a bright white centre to the band's " +
                "colour at the edge. An outer glow ring extends beyond the main disc for a neon " +
                "light effect. The cleanest and most readable shape.",
                tip: "Best all-around shape for most music types."
            ),
            HelpItem("★", "Star",
                "A five-pointed star filled with the sub-band radial gradient. The inner radius " +
                "is about 42% of the outer radius, giving a sharp, defined star shape. An outer " +
                "glow ring matches the circle shape for visual consistency.",
                tip: "Stars at high placement randomness look spectacular with electronic music."
            ),
            HelpItem("■", "2D Box",
                "A filled square with a radial gradient emanating from its centre, and outlined " +
                "edges. The square's side length is proportional to the band's radius, so louder " +
                "sounds produce larger squares.",
                tip: "2D Box at zero placement (Grid-locked) creates clean columns of squares " +
                     "like a traditional spectrum analyser."
            ),
            HelpItem("⬡", "3D Box  (Rotating)",
                "A wireframe cube that continuously rotates around its vertical axis at one full " +
                "revolution every 2 seconds. Uses perspective projection so edges closer to the " +
                "viewer appear larger. Front edges are brighter than back edges. Each edge is " +
                "individually tinted by the sub-band energy at its depth.",
                tip: "The 3D Box looks best with sub-band shading set to 4 or more rings, which " +
                     "makes each face of the cube glow differently."
            ),
            HelpItem("◉", "Sphere  (Rotating)",
                "A shaded sphere with 3 latitude lines and 3 longitude lines that rotate " +
                "continuously. The base disc uses sub-band radial shading. Each line's brightness " +
                "is individually driven by its corresponding sub-band energy — so different lines " +
                "can glow at different intensities depending on the frequency content.",
                tip: "Sphere with 8+ sub-band rings and a long lifetime creates a beautiful " +
                     "slowly-evolving planet-like display."
            )
        ]
    ),

    HelpSection("Sub-Band Shading", [
        HelpItem("🌈", "Sub-Band Shading",
            range: "1 (Off) – 12 rings", defaultVal: "4",
            "Each frequency band is divided into this many sub-slices. The energy in each slice " +
            "determines the brightness of one radial ring in the shape — innermost ring = lowest " +
            "frequency within the band, outermost ring = highest.\n\n" +
            "At 1 (Off), all shapes have a solid uniform colour with a white centre highlight. " +
            "At 12, each shape has 12 independently lit rings — very fine internal detail.",
            tip: "4–6 rings is a sweet spot — visible detail without overwhelming the overall " +
                 "colour. Try 1 for a cleaner look, or 12 for maximum visual complexity."
        )
    ]),

    HelpSection("Colour", [
        HelpItem("🟣", "Rainbow  (Color Scheme)",
            defaultVal: "Default",
            "Maps frequencies to colours following the visible light spectrum — bass frequencies " +
            "(30 Hz) appear violet/purple, moving through blue, cyan, green, yellow, to red at " +
            "treble (11 kHz). This mirrors how light works: low frequencies are warm/violet, " +
            "high frequencies are energetic/red.",
            tip: "Rainbow is the most intuitive mapping for musicians — bass is cool and deep, " +
                 "treble is warm and bright."
        ),
        HelpItem("🔴", "Inverse Rainbow  (Color Scheme)",
            "The reverse of Rainbow — bass frequencies appear red/warm and treble frequencies " +
            "appear violet/cool. Some people find this more intuitive since bass feels warm and " +
            "heavy while high frequencies feel cool and delicate.",
            tip: "Try Inverse Rainbow with the Sphere shape for a striking different look."
        ),
        HelpItem("🎨", "Band Colours",
            defaultVal: "Auto",
            "Opens the Band Colours screen where you can assign a completely custom colour to " +
            "any individual frequency band using a full HSV colour picker. Tap any band's colour " +
            "swatch to open the picker — drag the hue bar to choose a colour, then drag the " +
            "square to adjust brightness and saturation.\n\n" +
            "Bands without an override continue to follow the selected colour scheme. " +
            "Tap ✕ next to any band to remove its override. Tap RESET to clear all overrides.",
            tip: "Try making all bass bands red and all treble bands blue for a dramatic visual " +
                 "contrast, independent of the colour scheme setting."
        )
    ]),

    HelpSection("Tips & Tricks", [
        HelpItem("🎵", "Best Settings for Music",
            "Bands: 16–20  ·  Lifetime: 400–600 ms  ·  Placement: 0.3–0.5\n" +
            "Sub-Band Shading: 4–6  ·  Shape: Sphere or Circle  ·  Sensitivity: ×1.0",
            tip: "Try pointing the phone at your speaker and lowering the lights for a " +
                 "full light-show effect."
        ),
        HelpItem("🗣", "Best Settings for Voice",
            "Bands: 8–12  ·  Lifetime: 500–800 ms  ·  Placement: 0.2\n" +
            "Sensitivity: ×1.5–×2.0  ·  Sub-Band Shading: 1–2  ·  Shape: Circle or Star",
            tip: "Voice content is concentrated below 4 kHz — fewer bands means each active " +
                 "band produces a larger, more visible shape."
        ),
        HelpItem("🌙", "Best Settings for Ambient / Quiet",
            "Sensitivity: ×2.0–×3.0  ·  Lifetime: 800–1500 ms  ·  Min Size: 20–40 pt\n" +
            "Placement: 0.7–1.0  ·  Shape: Sphere  ·  Sub-Band Shading: 6–8",
            tip: "High sensitivity and long lifetime let even very quiet ambient sounds " +
                 "produce a gentle, slowly drifting display."
        ),
        HelpItem("📺", "Classic Spectrum Analyser Look",
            "Shape: 2D Box  ·  Placement: 0.0 (Grid-locked)  ·  Bands: 24\n" +
            "Lifetime: 200–300 ms  ·  Sub-Band Shading: 1 (Off)  ·  Color Scheme: Rainbow",
            tip: "This recreates the look of a traditional hardware spectrum analyser with " +
                 "crisp columns of coloured blocks."
        )
    ])
]

// MARK: - Main screen

struct HelpView: View {
    let onClose: () -> Void

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {

                    // Header
                    helpHeader

                    // Sections
                    ForEach(helpSections.indices, id: \.self) { si in
                        let section = helpSections[si]
                        SectionHeadingView(text: section.heading)

                        if !section.intro.isEmpty {
                            Text(section.intro)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(subtleC)
                                .lineSpacing(4)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        ForEach(section.items.indices, id: \.self) { ii in
                            HelpCardView(item: section.items[ii])
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)
                        }

                        Spacer().frame(height: 8)
                    }

                    // Footer
                    Text("ChromaSound  ·  Real-Time Audio Visualiser")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(subtleC.opacity(0.5))
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
            }
        }
    }

    private var helpHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: onClose) {
                    Text("← BACK")
                        .font(.system(size: 11, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(textC)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .overlay(Capsule().stroke(subtleC, lineWidth: 1))
                }
                Spacer()
                Text("HELP")
                    .font(.system(size: 18, design: .monospaced).weight(.black))
                    .foregroundColor(textC)
                    .tracking(4)
                Spacer()
                Spacer().frame(width: 80)
            }
            .padding(.top, 56)
            .padding(.horizontal, 20)

            Text("A guide to every control in ChromaSound")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(subtleC)
                .padding(.bottom, 20)
        }
    }
}

// MARK: - Section heading

private struct SectionHeadingView: View {
    let text: String

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(LinearGradient(
                    colors: [.clear, accentC.opacity(0.4)],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(height: 1)
            Text("  \(text)  ")
                .font(.system(size: 11, design: .monospaced).weight(.bold))
                .foregroundColor(accentC)
                .tracking(2)
                .fixedSize()
            Rectangle()
                .fill(LinearGradient(
                    colors: [accentC.opacity(0.4), .clear],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

// MARK: - Help card

private struct HelpCardView: View {
    let item: HelpItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Title row
            HStack(alignment: .center, spacing: 12) {
                // Emoji badge
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accentC.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(accentC.opacity(0.25), lineWidth: 1)
                        )
                        .frame(width: 42, height: 42)
                    Text(item.emoji).font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 14, design: .monospaced).weight(.bold))
                        .foregroundColor(textC)

                    // Range / default badges
                    if !item.range.isEmpty || !item.defaultVal.isEmpty {
                        HStack(spacing: 8) {
                            if !item.range.isEmpty {
                                BadgeView(label: "RANGE", value: item.range, color: subtleC)
                            }
                            if !item.defaultVal.isEmpty {
                                BadgeView(label: "DEFAULT", value: item.defaultVal, color: accentC)
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding(.bottom, 12)

            Divider()
                .background(subtleC.opacity(0.15))
                .padding(.bottom, 12)

            // Description — handle \n\n for paragraph breaks
            let paragraphs = item.description.components(separatedBy: "\n\n")
            ForEach(paragraphs.indices, id: \.self) { pi in
                Text(paragraphs[pi].trimmingCharacters(in: .whitespaces))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(textC.opacity(0.85))
                    .lineSpacing(4)
                    .padding(.bottom, pi < paragraphs.count - 1 ? 8 : 0)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Tip box
            if !item.tip.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Text("💡")
                        .font(.system(size: 14))
                        .padding(.top, 1)
                    Text(item.tip)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(tipGreen.opacity(0.9))
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(10)
                .background(tipGreen.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(tipGreen.opacity(0.25), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.top, 10)
            }
        }
        .padding(18)
        .background(cardBg, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Badge

private struct BadgeView: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8, design: .monospaced).weight(.bold))
                .foregroundColor(color.opacity(0.7))
                .tracking(1)
            Text(value)
                .font(.system(size: 10, design: .monospaced).weight(.bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 4))
    }
}
