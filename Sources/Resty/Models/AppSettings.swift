import Foundation

enum BreakBackgroundMode: String, Codable, CaseIterable {
    case hills
    case image
}

enum WorkingWeekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    var shortTitle: String {
        switch self {
        case .sunday:
            return "Sun"
        case .monday:
            return "Mon"
        case .tuesday:
            return "Tue"
        case .wednesday:
            return "Wed"
        case .thursday:
            return "Thu"
        case .friday:
            return "Fri"
        case .saturday:
            return "Sat"
        }
    }
}

struct AppSettings: Codable, Equatable {
    static let legacyFocusBundleIdentifiers: [String] = [
        "com.apple.dt.Xcode",
        "com.microsoft.VSCode",
        "md.obsidian",
        "com.jetbrains.intellij"
    ]

    var workInterval: TimeInterval = 20 * 60
    var breakDuration: TimeInterval = 20
    var preBreakReminderLeadTime: TimeInterval = 60
    var reminderAutoDismissTime: TimeInterval = 20
    var workingHoursEnabled: Bool = false
    var workingHoursStartMinutes: Int = 9 * 60
    var workingHoursEndMinutes: Int = 17 * 60
    var workingDays: Set<Int> = [2, 3, 4, 5, 6]
    var idlePauseThreshold: TimeInterval = 5 * 60
    var detectorCooldown: TimeInterval = 10
    var skipCooldown: TimeInterval = 8
    var allowEarlyEnd: Bool = true
    var soundEnabled: Bool = false
    var smartPauseMeetings: Bool = true
    var smartPauseVideoPlayback: Bool = true
    var smartPauseFullscreen: Bool = true
    var smartPauseScreenCapture: Bool = true
    var smartPauseFocusApps: Bool = false
    var focusBundleIdentifiers: [String] = []
    var customBreakMessage: String = "Step back and reset for a moment"
    var breakBackgroundMode: BreakBackgroundMode = .hills
    var customBreakBackgroundImagePath: String = ""

    func isWithinWorkingHours(at date: Date, calendar: Calendar = .current) -> Bool {
        guard workingHoursEnabled else { return true }

        let weekday = calendar.component(.weekday, from: date)
        guard workingDays.contains(weekday) else { return false }

        let components = calendar.dateComponents([.hour, .minute], from: date)
        let currentMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)

        if workingHoursStartMinutes == workingHoursEndMinutes {
            return true
        }

        if workingHoursStartMinutes < workingHoursEndMinutes {
            return currentMinutes >= workingHoursStartMinutes && currentMinutes < workingHoursEndMinutes
        }

        return currentMinutes >= workingHoursStartMinutes || currentMinutes < workingHoursEndMinutes
    }

    var hasCustomBreakBackgroundImage: Bool {
        !customBreakBackgroundImagePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
