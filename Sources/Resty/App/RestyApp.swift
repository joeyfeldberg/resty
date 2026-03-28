import SwiftUI

@main
struct RestyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            if let settingsStore = appDelegate.settingsStore,
               let permissionsManager = appDelegate.permissionsManager {
                SettingsView(settingsStore: settingsStore, permissionsManager: permissionsManager)
            } else {
                Text("Loading…")
                    .frame(width: 320, height: 200)
            }
        }
    }
}
