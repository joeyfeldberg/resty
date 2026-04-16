import XCTest
@testable import Resty

@MainActor
final class WorkingHoursTests: XCTestCase {
    func testSchedulerSuspendsOutsideWorkingHours() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.settings.workingHoursEnabled = true
        settingsStore.settings.workingHoursStartMinutes = 9 * 60
        settingsStore.settings.workingHoursEndMinutes = 17 * 60
        settingsStore.settings.workingDays = [2, 3, 4, 5, 6]

        let calendar = Calendar.current
        let outside = calendar.date(from: DateComponents(year: 2026, month: 3, day: 27, hour: 20, minute: 0))!

        let coordinator = BreakCoordinator(
            settingsStore: settingsStore,
            defaults: defaults,
            detectors: [],
            autoStartMonitoring: false,
            currentDateProvider: { outside }
        )

        coordinator.tickForTesting(at: outside)

        XCTAssertEqual(coordinator.session.state, .suspendedOutsideSchedule)
        XCTAssertEqual(coordinator.statusText, "Off")
        XCTAssertEqual(coordinator.statusIcon, .eyeClosed)
    }

    func testSchedulerResetsCountdownWhenWorkingHoursBegin() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.settings.workingHoursEnabled = true
        settingsStore.settings.workingHoursStartMinutes = 9 * 60
        settingsStore.settings.workingHoursEndMinutes = 17 * 60
        settingsStore.settings.workingDays = [2, 3, 4, 5, 6]

        let calendar = Calendar.current
        let outside = calendar.date(from: DateComponents(year: 2026, month: 3, day: 27, hour: 20, minute: 0))!
        let inside = calendar.date(from: DateComponents(year: 2026, month: 3, day: 30, hour: 10, minute: 0))!

        let coordinator = BreakCoordinator(
            settingsStore: settingsStore,
            defaults: defaults,
            detectors: [],
            autoStartMonitoring: false,
            currentDateProvider: { outside }
        )

        coordinator.tickForTesting(at: outside)
        coordinator.tickForTesting(at: inside)

        XCTAssertEqual(coordinator.session.state, .countingDown)
        XCTAssertEqual(coordinator.session.nextBreakDate, inside.addingTimeInterval(settingsStore.settings.workInterval))
    }

    func testSchedulerSuspendsOnInactiveWeekdayEvenInsideTimeWindow() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.settings.workingHoursEnabled = true
        settingsStore.settings.workingHoursStartMinutes = 9 * 60
        settingsStore.settings.workingHoursEndMinutes = 17 * 60
        settingsStore.settings.workingDays = [2, 3, 4, 5, 6]

        let calendar = Calendar.current
        let saturdayMorning = calendar.date(from: DateComponents(year: 2026, month: 3, day: 28, hour: 10, minute: 0))!

        let coordinator = BreakCoordinator(
            settingsStore: settingsStore,
            defaults: defaults,
            detectors: [],
            autoStartMonitoring: false,
            currentDateProvider: { saturdayMorning }
        )

        coordinator.tickForTesting(at: saturdayMorning)

        XCTAssertEqual(coordinator.session.state, .suspendedOutsideSchedule)
        XCTAssertEqual(coordinator.statusText, "Off")
    }
}
