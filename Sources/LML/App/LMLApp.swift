import SwiftUI
import LMLCore

@main
struct LMLApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(viewModel: appDelegate.menuBarVM)
        } label: {
            Text("⟨/⟩")
                .font(.system(size: 12, design: .monospaced))
        }

        Settings {
            SettingsView(viewModel: appDelegate.settingsVM)
        }
    }
}
