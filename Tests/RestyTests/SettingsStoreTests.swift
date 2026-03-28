import XCTest
@testable import Resty

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testSettingsPersistAcrossInstances() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let store = SettingsStore(defaults: defaults)
        store.settings.workInterval = 45 * 60
        store.settings.customBreakMessage = "Look away and reset"
        store.settings.focusBundleIdentifiers = ["com.apple.Safari", "com.apple.dt.Xcode"]

        let reloaded = SettingsStore(defaults: defaults)

        XCTAssertEqual(reloaded.settings.workInterval, 45 * 60)
        XCTAssertEqual(reloaded.settings.customBreakMessage, "Look away and reset")
        XCTAssertEqual(reloaded.settings.focusBundleIdentifiers, ["com.apple.Safari", "com.apple.dt.Xcode"])
    }

    func testLegacyFocusAppDefaultsAreMigratedOff() throws {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        var legacySettings = AppSettings()
        legacySettings.focusBundleIdentifiers = AppSettings.legacyFocusBundleIdentifiers

        defaults.set(try JSONEncoder().encode(legacySettings), forKey: "resty.settings")

        let migrated = SettingsStore(defaults: defaults)

        XCTAssertFalse(migrated.settings.smartPauseFocusApps)
        XCTAssertEqual(migrated.settings.focusBundleIdentifiers, [])
    }
}
