import Combine
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var settings: AppSettings {
        didSet { save() }
    }

    private let defaults: UserDefaults
    private let key = "resty.settings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = SettingsStore.migratedSettings(from: decoded)
        } else {
            self.settings = AppSettings()
        }
    }

    private static func migratedSettings(from settings: AppSettings) -> AppSettings {
        var migrated = settings
        if migrated.focusBundleIdentifiers == AppSettings.legacyFocusBundleIdentifiers {
            migrated.focusBundleIdentifiers = []
            migrated.smartPauseFocusApps = false
        }
        return migrated
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
    }
}
