import AppIntents
import RestyShared
import SwiftUI
import WidgetKit

@main
@available(macOS 26.0, *)
struct RestyControlsExtensionBundle: WidgetBundle {
    var body: some Widget {
        RestyReminderToggleControl()
        RestyStartBreakControl()
        RestySkipRoundControl()
    }
}

@available(macOS 26.0, *)
private struct RestyReminderToggleControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "local.resty.controls.reminders") {
            ControlWidgetToggle(
                "Resty Reminders",
                isOn: RestyControlStateStore().snapshot().isRemindersActive,
                action: SetRestyRemindersActiveIntent()
            ) { isActive in
                Label(
                    isActive ? "Running" : "Paused",
                    systemImage: isActive ? "eye" : "eye.slash"
                )
            }
            .tint(.teal)
        }
        .displayName("Resty Reminders")
        .description("Pause or resume Resty break reminders.")
    }
}

@available(macOS 26.0, *)
private struct RestyStartBreakControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "local.resty.controls.startBreak") {
            ControlWidgetButton(action: StartRestyBreakIntent()) {
                Label("Start Break", systemImage: "eye.trianglebadge.exclamationmark")
            }
            .tint(.teal)
        }
        .displayName("Start Resty Break")
        .description("Start a Resty break immediately.")
    }
}

@available(macOS 26.0, *)
private struct RestySkipRoundControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "local.resty.controls.skipRound") {
            ControlWidgetButton(action: SkipRestyRoundIntent()) {
                Label("Skip Round", systemImage: "forward.end")
            }
            .tint(.teal)
        }
        .displayName("Skip Resty Round")
        .description("Skip the next Resty break round.")
    }
}

@available(macOS 26.0, *)
private struct SetRestyRemindersActiveIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Set Resty Reminders"
    static let description = IntentDescription("Pause or resume Resty reminders.")

    @Parameter(title: "Running")
    var value: Bool

    func perform() async throws -> some IntentResult {
        RestyControlStateStore().writeCommand(
            RestyControlCommand(kind: value ? .resume : .pause)
        )
        ControlCenter.shared.reloadControls(ofKind: "local.resty.controls.reminders")
        return .result()
    }
}

@available(macOS 26.0, *)
private struct StartRestyBreakIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Resty Break"
    static let description = IntentDescription("Start a Resty break immediately.")

    func perform() async throws -> some IntentResult {
        RestyControlStateStore().writeCommand(
            RestyControlCommand(kind: .startBreak)
        )
        ControlCenter.shared.reloadControls(ofKind: "local.resty.controls.startBreak")
        return .result()
    }
}

@available(macOS 26.0, *)
private struct SkipRestyRoundIntent: AppIntent {
    static let title: LocalizedStringResource = "Skip Resty Round"
    static let description = IntentDescription("Skip the next Resty break round.")

    func perform() async throws -> some IntentResult {
        RestyControlStateStore().writeCommand(
            RestyControlCommand(kind: .skipRound)
        )
        ControlCenter.shared.reloadControls(ofKind: "local.resty.controls.skipRound")
        return .result()
    }
}
