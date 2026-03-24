import SwiftUI

struct ContentView: View {
    @StateObject private var vm = ChromaSoundViewModel()
    @State private var showSettings   = false
    @State private var showBandColors = false

    var body: some View {
        ZStack {
            if showBandColors {
                BandColorView(vm: vm, onClose: { showBandColors = false })
            } else if showSettings {
                SettingsView(
                    vm: vm,
                    onClose:          { showSettings = false },
                    onOpenBandColors: { showSettings = false; showBandColors = true }
                )
            } else {
                MainView(vm: vm, onSettings: { showSettings = true })
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSettings)
        .animation(.easeInOut(duration: 0.2), value: showBandColors)
    }
}
