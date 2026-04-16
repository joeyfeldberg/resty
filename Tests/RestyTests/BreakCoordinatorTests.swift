import XCTest
@testable import Resty
@testable import RestyShared

@MainActor
final class BreakCoordinatorTests: XCTestCase {
    func testSubtractMinuteClampsToNowAndStartsBreak() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.settings.workInterval = 5 * 60
        settingsStore.settings.preBreakReminderLeadTime = 60
        settingsStore.settings.breakDuration = 20
        let start = Date(timeIntervalSince1970: 1_000)

        let coordinator = BreakCoordinator(
            settingsStore: settingsStore,
            defaults: defaults,
            detectors: [],
            autoStartMonitoring: false,
            currentDateProvider: { start }
        )

        coordinator.setCurrentTimeForTesting(start)
        coordinator.extend(by: -(5 * 60))

        XCTAssertEqual(coordinator.session.state, .onBreak)
        XCTAssertEqual(coordinator.session.breakEndDate, start.addingTimeInterval(20))
        XCTAssertEqual(coordinator.timeUntilBreak, 0)
    }

    func testSubtractMinuteInsideLeadTimeKeepsPreBreakReminderVisible() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.settings.workInterval = 5 * 60
        settingsStore.settings.preBreakReminderLeadTime = 60
        let start = Date(timeIntervalSince1970: 2_000)

        let coordinator = BreakCoordinator(
            settingsStore: settingsStore,
            defaults: defaults,
            detectors: [],
            autoStartMonitoring: false,
            currentDateProvider: { start }
        )

        coordinator.setCurrentTimeForTesting(start)
        coordinator.extend(by: -(4 * 60 + 30))

        XCTAssertEqual(coordinator.session.state, .preBreakReminder)
        XCTAssertEqual(Int(coordinator.timeUntilBreak), 30)
    }

    func testExtendMovesReminderBackToCountingDown() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.settings.workInterval = 5 * 60
        settingsStore.settings.preBreakReminderLeadTime = 60
        let start = Date(timeIntervalSince1970: 3_000)

        let coordinator = BreakCoordinator(
            settingsStore: settingsStore,
            defaults: defaults,
            detectors: [],
            autoStartMonitoring: false,
            currentDateProvider: { start }
        )

        coordinator.setCurrentTimeForTesting(start)
        coordinator.extend(by: -(4 * 60 + 30))
        coordinator.extend(by: 90)

        XCTAssertEqual(coordinator.session.state, .countingDown)
        XCTAssertEqual(Int(coordinator.timeUntilBreak), 120)
    }

    func testFloatingCountdownAppearsAtTenSeconds() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.settings.workInterval = 5 * 60
        settingsStore.settings.preBreakReminderLeadTime = 60
        let start = Date(timeIntervalSince1970: 7_000)

        let coordinator = BreakCoordinator(
            settingsStore: settingsStore,
            defaults: defaults,
            detectors: [],
            autoStartMonitoring: false,
            currentDateProvider: { start }
        )

        coordinator.setCurrentTimeForTesting(start)
        coordinator.extend(by: -(4 * 60 + 50))

        XCTAssertEqual(Int(coordinator.timeUntilBreak), 10)
        XCTAssertTrue(coordinator.shouldShowFloatingCountdown)

        coordinator.extend(by: 1)

        XCTAssertEqual(Int(coordinator.timeUntilBreak), 11)
        XCTAssertFalse(coordinator.shouldShowFloatingCountdown)
    }

    func testReminderAndCursorCountdownUseSameDisplayedSeconds() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)

        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.settings.workInterval = 5 * 60
        settingsStore.settings.preBreakReminderLeadTime = 60
        let start = Date(timeIntervalSince1970: 8_000)

        let coordinator = BreakCoordinator(
            settingsStore: settingsStore,
            defaults: defaults,
            detectors: [],
            autoStartMonitoring: false,
            currentDateProvider: { start }
        )

        coordinator.setCurrentTimeForTesting(start)
        coordinator.extend(by: -(4 * 60 + 51))
        coordinator.setCurrentTimeForTesting(start.addingTimeInterval(0.4))

        XCTAssertEqual(coordinator.displayedBreakSeconds, 9)
        XCTAssertEqual(coordinator.preBreakCountdownText, "9")
        XCTAssertEqual(coordinator.headlineText, "Pause coming - 9")
    }

    func testControlCenterCommandsPauseAndResumeCoordinator() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let controlSuiteName = "\(#function).controls"
        let controlDefaults = UserDefaults(suiteName: controlSuiteName)!
        controlDefaults.removePersistentDomain(forName: controlSuiteName)
        let controlStore = RestyControlStateStore(defaults: controlDefaults)

        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let settingsStore = SettingsStore(defaults: defaults)
        let coordinator = BreakCoordinator(
            settingsStore: settingsStore,
            defaults: defaults,
            detectors: [],
            controlStateStore: controlStore,
            autoStartMonitoring: false,
            currentDateProvider: { now }
        )

        controlStore.writeCommand(RestyControlCommand(kind: .pause))
        coordinator.tickForTesting(at: now.addingTimeInterval(1))

        XCTAssertEqual(coordinator.session.state, .pausedManual)
        XCTAssertNil(controlStore.pendingCommand())
        XCTAssertFalse(controlStore.snapshot().isRemindersActive)

        controlStore.writeCommand(RestyControlCommand(kind: .resume))
        coordinator.tickForTesting(at: now.addingTimeInterval(2))

        XCTAssertEqual(coordinator.session.state, .countingDown)
        XCTAssertNil(controlStore.pendingCommand())
        XCTAssertTrue(controlStore.snapshot().isRemindersActive)
    }
}
