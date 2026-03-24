# ChromaSound iOS 🎨🎵
### Sound → FFT → Color · iPhone App

Built with Swift + SwiftUI + Apple's Accelerate framework (vDSP hardware-accelerated FFT).

---

## Build on GitHub — No Mac Required

### Step 1 — Create a GitHub repository
1. Go to github.com → **+** → **New repository**
2. Name it `chromasound-ios`, leave all defaults
3. Click **Create repository**

### Step 2 — Upload all project files
1. On the empty repository page click **uploading an existing file**
2. Show hidden files first (Win: View → Hidden items / Mac: Cmd+Shift+.)
3. Drag ALL files from this folder into the browser — including `.github/` and `.gitignore`
4. Commit message: `Initial commit`
5. Click **Commit changes**

### Step 3 — Watch the build
1. Click the **Actions** tab
2. The workflow **Build ChromaSound iOS** starts automatically
3. The first step builds for **iOS Simulator** (no signing needed — always runs)
4. When green ✅, the build succeeded

> The simulator build confirms your code compiles correctly.
> To install on a real iPhone, see the Signing section below.

---

## Installing on a Real iPhone

iOS requires code-signing. You need a **free Apple ID** for personal device use,
or an **Apple Developer account ($99/year)** to share with others.

### Option A — Free Apple ID (personal use, 7-day certificate)

This requires Xcode on a Mac once to generate a certificate.
If you have a friend with a Mac, or access to one briefly, this is the easiest path.

1. On the Mac: open Xcode → Preferences → Accounts → add your Apple ID
2. Open the ChromaSound project in Xcode
3. Select the ChromaSound target → Signing & Capabilities → sign in with your Apple ID
4. Connect your iPhone and select it as the build destination
5. Run — Xcode installs the app directly

### Option B — Apple Developer Program ($99/year)

Allows building and distributing an IPA via ad-hoc or TestFlight.

#### Generate signing certificate and provisioning profile
1. Go to developer.apple.com → Certificates, Identifiers & Profiles
2. Create an App ID: `com.chromasound.app`
3. Create a Distribution certificate (download as .p12, set a password)
4. Create an Ad Hoc provisioning profile for your device UDID
5. Download the .mobileprovision file

#### Encode for GitHub Secrets
```bash
# On any computer:
base64 -i YourCert.p12 -o cert_b64.txt
base64 -i YourProfile.mobileprovision -o pp_b64.txt
```

#### Add GitHub Secrets
Go to your repo → **Settings → Secrets and variables → Actions**:

| Secret name | Value |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | Contents of cert_b64.txt |
| `P12_PASSWORD` | The password you set on the .p12 |
| `BUILD_PROVISION_BASE64` | Contents of pp_b64.txt |
| `KEYCHAIN_PASSWORD` | Any password you choose (e.g. `temp1234`) |

#### Trigger a signed build
Go to **Actions → Build ChromaSound iOS → Run workflow**
→ The IPA is attached to the workflow artifacts when complete.

#### Install the IPA
- Email the IPA to yourself and open it on iPhone (prompts to install)
- Or use Apple Configurator 2 (free on Mac App Store)
- Or use a service like Diawi (diawi.com) to generate a QR code

---

## Architecture

```
ChromaSound/
├── ChromaSoundApp.swift          App entry point (@main)
├── Audio/
│   └── AudioEngine.swift         AVAudioEngine → vDSP FFT → AudioFrame
├── FFT/
│   └── ColorMapper.swift         Frequency → Color mapping
├── Model/
│   └── Models.swift              Settings, FrequencyCircle, BandDefinition
├── UI/
│   ├── ViewModel.swift           ObservableObject — state + frame processing
│   ├── ContentView.swift         Root navigation
│   ├── MainView.swift            Idle + running canvas + HUD
│   ├── SettingsView.swift        All sliders, shape selector, color scheme
│   ├── BandColorView.swift       Per-band color overrides + HSV picker
│   └── Shapes/
│       └── ShapeDrawing.swift    5 draw functions using SwiftUI Canvas
└── Resources/
    └── Info.plist                Microphone permission string
```

## Feature parity with Android version

| Feature | iOS |
|---|---|
| FFT engine | Apple vDSP (hardware-accelerated) |
| Band count slider (2–24) | ✅ |
| Circle lifetime slider | ✅ |
| Objects per band slider | ✅ |
| Min/max size sliders | ✅ |
| Placement randomness slider | ✅ |
| Mic sensitivity slider | ✅ |
| Sub-band shading slider (1–12 rings) | ✅ |
| Rainbow / Inverse Rainbow color scheme | ✅ |
| 5 shapes: Circle, Star, 2D Box, 3D Box, Sphere | ✅ |
| 3D Box and Sphere rotating animations | ✅ |
| Per-band color override with HSV picker | ✅ |
| Band breakdown table in settings | ✅ |
