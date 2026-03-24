import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ChromaSoundViewModel()
    @State private var showSettings   = false
    @State private var showBandColors = false
    @State private var showHelp       = false

    var body: some View {
        ZStack {
            if showHelp {
                HelpView(onClose: { showHelp = false })
            } else if showBandColors {
                BandColorView(vm: vm, onClose: { showBandColors = false })
            } else if showSettings {
                SettingsView(
                    vm: vm,
                    onClose:          { showSettings = false },
                    onOpenBandColors: { showSettings = false; showBandColors = true },
                    onOpenHelp:       { showSettings = false; showHelp = true }
                )
            } else {
                MainView(vm: vm, onSettings: { showSettings = true })
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSettings)
        .animation(.easeInOut(duration: 0.2), value: showBandColors)
        .animation(.easeInOut(duration: 0.2), value: showHelp)
    }
}
