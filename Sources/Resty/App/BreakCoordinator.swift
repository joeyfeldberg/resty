import AppKit
import Combine
import Foundation
import RestyShared
import WidgetKit

@MainActor
final class BreakCoordinator: ObservableObject {
    static let floatingCountdownLeadTime: TimeInterval = 10

    @Published private(set) var session = BreakSessionState()
    @Published private(set) var now = Date()

    private let defaults: UserDefaults
    private let sessionKey = "resty.session"
    private let settingsStore: SettingsStore
    private let detectors: [ActivityDetector]
    private let controlStateStore: RestyControlStateStore
    private var timerCancellable: AnyCancellable?
    private var smartPauseCooldownUntil: Date?
    private let currentDateProvider: () -> Date
    private var lastHandledControlCommandID: UUID?

    init(
        settingsStore: SettingsStore,
        defaults: UserDefaults = .standard,
        detectors: [ActivityDetector]? = nil,
        controlStateStore: RestyControlStateStore = RestyControlStateStore(),
        autoStartMonitoring: Bool = true,
        currentDateProvider: @escaping () -> Date = Date.init
    ) {
        self.settingsStore = settingsStore
        self.defaults = defaults
        self.controlStateStore = controlStateStore
        self.currentDateProvider = currentDateProvider
        self.detectors = detectors ?? [
            MeetingDetector(),
            VideoPlaybackDetector(),
            FullscreenDetector(),
            ScreenCaptureDetector(),
            FocusAppDetector()
        ]
        self.now = currentDateProvider()

        if let data = defaults.data(forKey: sessionKey),
           let decoded = try? JSONDecoder().decode(BreakSessionState.self, from: data) {
            session = decoded
        } else {
            resetCountdown(from: self.now)
        }

        if autoStartMonitoring {
            startMonitoring()
        }
        publishControlSnapshot()
    }

    var settings: AppSettings { settingsStore.settings }

    var statusIcon: RestyIcon {
        switch session.state {
        case .suspendedOutsideSchedule:
            return .eyeClosed
        case .pausedManual, .pausedSmart:
            return .eyeOff
        default:
            return .eye
        }
    }

    var statusText: String {
        switch session.state {
        case .countingDown, .preBreakReminder:
            return timeString(for: timeUntilBreak)
        case .onBreak:
            return "Break"
        case .pausedManual:
            return "Paused"
        case .pausedSmart:
            return "Auto"
        case .breakStarting:
            return "Now"
        case .suspendedOutsideSchedule:
            return "Off"
        case .idle:
            return "Resty"
        }
    }

    var headlineText: String {
        switch session.state {
        case .preBreakReminder:
            return "Pause coming - \(preBreakCountdownText)"
        case .onBreak:
            return "Reset for \(timeString(for: timeRemainingInBreak))"
        case .pausedSmart:
            return session.smartPauseReasons.first ?? "Smart pause active"
        case .pausedManual:
            return "Break reminders paused"
        case .suspendedOutsideSchedule:
            return "Outside working hours"
        default:
            return "Next break in \(timeString(for: timeUntilBreak))"
        }
    }

    var shouldShowReminderPanel: Bool {
        session.state == .preBreakReminder
    }

    var shouldShowFloatingCountdown: Bool {
        session.state == .preBreakReminder && timeUntilBreak <= Self.floatingCountdownLeadTime
    }

    var shouldShowBreakOverlay: Bool {
        session.state == .onBreak || session.state == .breakStarting
    }

    var timeUntilBreak: TimeInterval {
        max(0, session.nextBreakDate.timeIntervalSince(now))
    }

    var timeRemainingInBreak: TimeInterval {
        max(0, (session.breakEndDate ?? now).timeIntervalSince(now))
    }

    var preBreakCountdownText: String {
        let totalSeconds = displayedBreakSeconds
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes > 0 {
            return String(format: "%02d:%02d", minutes, seconds)
        }

        return "\(seconds)"
    }

    var displayedBreakSeconds: Int {
        max(0, Int(timeUntilBreak.rounded(.up)))
    }

    func setCurrentTimeForTesting(_ date: Date) {
        now = date
    }

    func tickForTesting(at date: Date) {
        tick(at: date)
    }

    func startBreakNow() {
        session.state = .breakStarting
        session.breakStartedAt = now
        session.breakEndDate = now.addingTimeInterval(settings.breakDuration)
        persist()
        session.state = .onBreak
        persist()
    }

    func extend(by seconds: TimeInterval) {
        let candidateDate = max(session.nextBreakDate, now).addingTimeInterval(seconds)
        session.nextBreakDate = max(now, candidateDate)
        synchronizeCountdownState()
        persist()
    }

    func skipBreak() {
        session.lastBreakCompletedAt = now
        resetCountdown(from: now)
    }

    func toggleManualPause() {
        if session.state == .pausedManual {
            resetCountdown(from: now)
        } else {
            session.state = .pausedManual
            session.pausedAt = now
            persist()
        }
    }

    func endBreakEarly() {
        guard settings.allowEarlyEnd else { return }
        resetCountdown(from: now)
    }

    func updateSettings(_ transform: (inout AppSettings) -> Void) {
        var updated = settingsStore.settings
        transform(&updated)
        settingsStore.settings = updated
    }

    private func startMonitoring() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] value in
                self?.tick(at: value)
            }
    }

    private func tick(at date: Date) {
        now = date
        handlePendingControlCommand()

        if handleWorkingHours(at: date) {
            persist()
            return
        }

        evaluateSmartPause()

        switch session.state {
        case .countingDown:
            let idleTime = ProcessInfo.processInfo.systemUptime - CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .null)
            if idleTime >= settings.idlePauseThreshold {
                resetCountdown(from: now)
                return
            }

            if timeUntilBreak <= settings.preBreakReminderLeadTime {
                session.state = .preBreakReminder
                persist()
            }
        case .preBreakReminder:
            if timeUntilBreak <= 0 {
                startBreakNow()
            }
        case .onBreak:
            if timeRemainingInBreak <= 0 {
                resetCountdown(from: now)
            }
        case .pausedManual, .pausedSmart, .idle, .breakStarting, .suspendedOutsideSchedule:
            break
        }

        persist()
    }

    private func handleWorkingHours(at date: Date) -> Bool {
        guard settings.workingHoursEnabled else {
            if session.state == .suspendedOutsideSchedule {
                resetCountdown(from: date)
                return true
            }
            return false
        }

        guard settings.isWithinWorkingHours(at: date) else {
            if session.state == .onBreak {
                return false
            }

            if session.state != .suspendedOutsideSchedule {
                session.state = .suspendedOutsideSchedule
                session.smartPauseReasons = []
            }
            return true
        }

        if session.state == .suspendedOutsideSchedule {
            resetCountdown(from: date)
            return true
        }

        return false
    }

    private func evaluateSmartPause() {
        guard session.state != .pausedManual, session.state != .onBreak else { return }

        let activeReasons = detectors.compactMap { detector in
            let status = detector.status(using: settings)
            return status.isActive ? status.reason : nil
        }

        if !activeReasons.isEmpty {
            smartPauseCooldownUntil = nil
            session.state = .pausedSmart
            session.smartPauseReasons = activeReasons
            persist()
            return
        }

        if session.state == .pausedSmart {
            if let cooldownUntil = smartPauseCooldownUntil {
                guard now >= cooldownUntil else { return }
                smartPauseCooldownUntil = nil
                resetCountdown(from: now)
            } else {
                smartPauseCooldownUntil = now.addingTimeInterval(settings.detectorCooldown)
            }
        }
    }

    private func resetCountdown(from date: Date) {
        session = BreakSessionState(
            state: .countingDown,
            startedAt: date,
            nextBreakDate: date.addingTimeInterval(settings.workInterval),
            breakEndDate: nil,
            pausedAt: nil,
            deferredUntil: nil,
            smartPauseReasons: [],
            lastBreakCompletedAt: session.lastBreakCompletedAt,
            breakStartedAt: nil
        )
        persist()
    }

    private func synchronizeCountdownState() {
        guard session.state != .pausedManual, session.state != .pausedSmart, session.state != .onBreak else {
            return
        }

        if timeUntilBreak <= 0 {
            startBreakNow()
            return
        }

        if timeUntilBreak <= settings.preBreakReminderLeadTime {
            session.state = .preBreakReminder
        } else {
            session.state = .countingDown
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(session) else { return }
        defaults.set(data, forKey: sessionKey)
        publishControlSnapshot()
    }

    private func publishControlSnapshot() {
        let previousSnapshot = controlStateStore.snapshot()
        let snapshot = RestyControlSnapshot(
            isRemindersActive: session.state != .pausedManual,
            statusText: statusText,
            updatedAt: now,
            lastHandledCommandID: lastHandledControlCommandID
        )
        controlStateStore.saveSnapshot(snapshot)

        if #available(macOS 26.0, *),
           previousSnapshot.isRemindersActive != snapshot.isRemindersActive
            || previousSnapshot.lastHandledCommandID != snapshot.lastHandledCommandID {
            ControlCenter.shared.reloadControls(ofKind: "local.resty.controls.reminders")
            ControlCenter.shared.reloadControls(ofKind: "local.resty.controls.startBreak")
            ControlCenter.shared.reloadControls(ofKind: "local.resty.controls.skipRound")
        }
    }

    private func handlePendingControlCommand() {
        guard let command = controlStateStore.pendingCommand(),
              command.id != lastHandledControlCommandID else {
            return
        }

        switch command.kind {
        case .pause:
            if session.state != .pausedManual {
                session.state = .pausedManual
                session.pausedAt = now
            }
        case .resume:
            if session.state == .pausedManual {
                resetCountdown(from: now)
            }
        case .startBreak:
            startBreakNow()
        case .skipRound:
            skipBreak()
        }

        lastHandledControlCommandID = command.id
        controlStateStore.markCommandHandled(
            command,
            snapshot: RestyControlSnapshot(
                isRemindersActive: session.state != .pausedManual,
                statusText: statusText,
                updatedAt: now,
                lastHandledCommandID: lastHandledControlCommandID
            )
        )
        persist()
    }

    private func timeString(for interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded(.down)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        if minutes > 0 {
            return String(format: "%02d:%02d", minutes, seconds)
        }
        return "\(seconds)"
    }
}
