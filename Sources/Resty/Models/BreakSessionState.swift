import Foundation

enum SchedulerState: String, Codable {
    case idle
    case countingDown
    case preBreakReminder
    case breakStarting
    case onBreak
    case pausedManual
    case pausedSmart
    case suspendedOutsideSchedule
}

struct BreakSessionState: Codable, Equatable {
    var state: SchedulerState = .idle
    var startedAt: Date = .now
    var nextBreakDate: Date = .now.addingTimeInterval(20 * 60)
    var breakEndDate: Date?
    var pausedAt: Date?
    var deferredUntil: Date?
    var smartPauseReasons: [String] = []
    var lastBreakCompletedAt: Date?
    var breakStartedAt: Date?
}
