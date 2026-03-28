import XCTest
@testable import Resty

@MainActor
final class PreBreakInteractionTests: XCTestCase {
    func testPreBreakDoesNotAutoDelayDuringCountdownTicks() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.settings.workInterval = 5 * 60
        settingsStore.settings.preBreakReminderLeadTime = 60
        let start = Date(timeIntervalSince1970: 5_000)

        let coordinator = BreakCoordinator(
            settingsStore: settingsStore,
            defaults: defaults,
            detectors: [],
            autoStartMonitoring: false,
            currentDateProvider: { start }
        )

        coordinator.setCurrentTimeForTesting(start)
        coordinator.extend(by: -(4 * 60 + 30))
        coordinator.tickForTesting(at: start.addingTimeInterval(1))

        XCTAssertEqual(coordinator.session.state, .preBreakReminder)
        XCTAssertEqual(Int(coordinator.timeUntilBreak), 29)
    }

    func testPreBreakStartsBreakWhenCountdownExpiresWithoutDelayButton() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.settings.workInterval = 5 * 60
        settingsStore.settings.preBreakReminderLeadTime = 60
        settingsStore.settings.breakDuration = 20
        let start = Date(timeIntervalSince1970: 6_000)

        let coordinator = BreakCoordinator(
            settingsStore: settingsStore,
            defaults: defaults,
            detectors: [],
            autoStartMonitoring: false,
            currentDateProvider: { start }
        )

        coordinator.setCurrentTimeForTesting(start)
        coordinator.extend(by: -(5 * 60))
        coordinator.tickForTesting(at: start)

        XCTAssertEqual(coordinator.session.state, .onBreak)
        XCTAssertEqual(coordinator.session.breakEndDate, start.addingTimeInterval(20))
    }
}
