import Foundation

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

    func isWithinWorkingHours(at date: Date, calendar: Calendar = .current) -> Bool {
        guard workingHoursEnabled else { return true }

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
}
