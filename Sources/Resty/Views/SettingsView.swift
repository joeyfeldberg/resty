import SwiftUI
import AppKit

private enum SettingsSection: String, CaseIterable, Identifiable {
    case breaks = "Breaks"
    case behavior = "Behavior"
    case smartPause = "Smart Pause"
    case appearance = "Appearance"

    var id: String { rawValue }
}

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var permissionsManager: PermissionsManager
    @State private var selectedSection: SettingsSection = .breaks

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .overlay(Color.white.opacity(0.08))
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    sectionContent
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
        }
        .frame(width: 660, height: 560)
        .background(VisualStyle.settingsBackground)
        .onAppear {
            permissionsManager.refreshStatuses()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Resty Settings")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            HStack(spacing: 8) {
                ForEach(SettingsSection.allCases) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        Text(section.rawValue)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(selectedSection == section ? .white : Color.white.opacity(0.72))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule()
                                    .fill(selectedSection == section ? Color.white.opacity(0.14) : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(Color.white.opacity(0.05))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch selectedSection {
        case .breaks:
            SettingsCard(title: "Timing", detail: "Tune the cadence for reminders and breaks.") {
                stepperRow("Work interval", value: "\(Int(settingsStore.settings.workInterval / 60)) min") {
                    Stepper("", value: binding(\.workInterval), in: 5 * 60...90 * 60, step: 60)
                        .labelsHidden()
                }
                stepperRow("Break length", value: "\(Int(settingsStore.settings.breakDuration)) sec") {
                    Stepper("", value: binding(\.breakDuration), in: 10...120, step: 5)
                        .labelsHidden()
                }
                stepperRow("Reminder lead time", value: "\(Int(settingsStore.settings.preBreakReminderLeadTime)) sec") {
                    Stepper("", value: binding(\.preBreakReminderLeadTime), in: 10...300, step: 10)
                        .labelsHidden()
                }
            }

        case .behavior:
            SettingsCard(title: "Behavior", detail: "General break behavior outside the explicit delay buttons.") {
                toggleRow("Allow early end", isOn: binding(\.allowEarlyEnd))
                toggleRow("Sound enabled", isOn: binding(\.soundEnabled))
                stepperRow("Idle reset threshold", value: "\(Int(settingsStore.settings.idlePauseThreshold / 60)) min") {
                    Stepper("", value: binding(\.idlePauseThreshold), in: 60...1800, step: 60)
                        .labelsHidden()
                }
            }

            SettingsCard(title: "Working Hours", detail: "Only run break reminders during these hours.") {
                toggleRow("Enable working hours", isOn: binding(\.workingHoursEnabled))
                timePickerRow("Start time", selection: timeBinding(\.workingHoursStartMinutes))
                timePickerRow("End time", selection: timeBinding(\.workingHoursEndMinutes))
                weekdaySelectionRow()
            }

        case .smartPause:
            SettingsCard(title: "Detection", detail: "Pause reminders when calls, playback, or focused work are active.") {
                toggleRow("Meetings and calls", isOn: binding(\.smartPauseMeetings))
                toggleRow("Video playback", isOn: binding(\.smartPauseVideoPlayback))
                toggleRow("Fullscreen apps", isOn: binding(\.smartPauseFullscreen))
                toggleRow("Screen capture", isOn: binding(\.smartPauseScreenCapture))
                toggleRow("Focus apps", isOn: binding(\.smartPauseFocusApps))
                stepperRow("Resume cooldown", value: "\(Int(settingsStore.settings.detectorCooldown)) sec") {
                    Stepper("", value: binding(\.detectorCooldown), in: 5...120, step: 5)
                        .labelsHidden()
                }
            }

            SettingsCard(title: "Focus Apps", detail: "Optional bundle identifiers that can pause reminders when their app is frontmost.") {
                TextEditor(text: focusAppsBinding)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 170)
                    .background(Color.black.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }

            SettingsCard(title: "Permissions", detail: "Grant the system access needed for browser, meeting, and screen-aware detection.") {
                permissionRow(
                    "Browser automation",
                    status: permissionsManager.browserAutomationStatus,
                    detail: permissionsManager.browserAutomationTargetName
                ) {
                    permissionsManager.requestBrowserAutomationAccess()
                }
                permissionRow("Camera", status: permissionsManager.cameraStatus, detail: "Meeting activity") {
                    permissionsManager.requestCameraAccess()
                }
                permissionRow("Microphone", status: permissionsManager.microphoneStatus, detail: "Meeting activity") {
                    permissionsManager.requestMicrophoneAccess()
                }
                permissionRow("Screen recording", status: permissionsManager.screenRecordingStatus, detail: "Window and capture checks") {
                    permissionsManager.requestScreenRecordingAccess()
                }
                permissionRow("Accessibility", status: permissionsManager.accessibilityStatus, detail: "Future activity hooks") {
                    permissionsManager.requestAccessibilityAccess()
                }
            }

        case .appearance:
            SettingsCard(title: "Break Background", detail: "Choose the built-in hills scene or a custom image from disk.") {
                Picker("Break background", selection: binding(\.breakBackgroundMode)) {
                    ForEach(BreakBackgroundMode.allCases, id: \.self) { mode in
                        Text(backgroundModeTitle(mode)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if settingsStore.settings.breakBackgroundMode == .image {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Button("Choose Image…") {
                                chooseBreakBackgroundImage()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.white.opacity(0.18))

                            Button("Clear") {
                                clearBreakBackgroundImage()
                            }
                            .buttonStyle(.bordered)
                            .disabled(!settingsStore.settings.hasCustomBreakBackgroundImage)
                        }

                        Text(currentBackgroundImageLabel)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.58))
                    }
                    .padding(.top, 4)
                }
            }

            SettingsCard(title: "Copy", detail: "The message shown in reminders and on the break screen.") {
                TextField("Step back and reset for a moment", text: binding(\.customBreakMessage), axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(Color.black.opacity(0.22))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }

            SettingsCard(title: "Preview", detail: "Current reminder copy and controls style.") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pause coming - 00:58")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(settingsStore.settings.customBreakMessage)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.72))
                    HStack(spacing: 8) {
                        previewChip("Begin now")
                        previewChip("-5 min")
                        previewChip("-1 min")
                        previewChip("+1 min")
                        previewChip("+5 min")
                    }
                }
            }
        }
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(.vertical, 4)
    }

    private func stepperRow(_ title: String, value: String, @ViewBuilder control: () -> some View) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(value)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.58))
            }
            Spacer()
            control()
        }
        .padding(.vertical, 4)
    }

    private func timePickerRow(_ title: String, selection: Binding<Date>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
            DatePicker("", selection: selection, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .colorScheme(.dark)
        }
        .padding(.vertical, 4)
    }

    private func previewChip(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.86))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private func weekdaySelectionRow() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active days")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                ForEach(WorkingWeekday.allCases) { weekday in
                    Button {
                        toggleWorkingDay(weekday)
                    } label: {
                        Text(weekday.shortTitle)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(isWorkingDaySelected(weekday) ? .black : .white.opacity(0.80))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isWorkingDaySelected(weekday) ? Color.white.opacity(0.92) : Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(isWorkingDaySelected(weekday) ? 0 : 0.08), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func permissionRow(_ title: String, status: PermissionStatus, detail: String, action: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.58))
            }
            Spacer()
            Text(status.label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white.opacity(0.08))
                .clipShape(Capsule())

            Button(status.actionTitle, action: action)
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.18))
                .disabled(status == .authorized || status == .unavailable)
        }
        .padding(.vertical, 4)
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { settingsStore.settings[keyPath: keyPath] },
            set: { settingsStore.settings[keyPath: keyPath] = $0 }
        )
    }

    private func timeBinding(_ keyPath: WritableKeyPath<AppSettings, Int>) -> Binding<Date> {
        Binding(
            get: {
                let totalMinutes = settingsStore.settings[keyPath: keyPath]
                let hours = totalMinutes / 60
                let minutes = totalMinutes % 60
                return Calendar.current.date(
                    from: DateComponents(hour: hours, minute: minutes)
                ) ?? .now
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                settingsStore.settings[keyPath: keyPath] = (components.hour ?? 0) * 60 + (components.minute ?? 0)
            }
        )
    }

    private var focusAppsBinding: Binding<String> {
        Binding(
            get: { settingsStore.settings.focusBundleIdentifiers.joined(separator: "\n") },
            set: { newValue in
                settingsStore.settings.focusBundleIdentifiers = newValue
                    .split(whereSeparator: \.isNewline)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }
        )
    }

    private var currentBackgroundImageLabel: String {
        let path = settingsStore.settings.customBreakBackgroundImagePath
        if path.isEmpty {
            return "No image selected."
        }

        return URL(fileURLWithPath: path).lastPathComponent
    }

    private func backgroundModeTitle(_ mode: BreakBackgroundMode) -> String {
        switch mode {
        case .hills:
            return "Hills"
        case .image:
            return "Image"
        }
    }

    private func chooseBreakBackgroundImage() {
        let panel = NSOpenPanel()
        panel.title = "Choose Break Background"
        panel.prompt = "Use Image"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]

        guard panel.runModal() == .OK, let url = panel.url else { return }
        settingsStore.settings.customBreakBackgroundImagePath = url.path
        settingsStore.settings.breakBackgroundMode = .image
    }

    private func clearBreakBackgroundImage() {
        settingsStore.settings.customBreakBackgroundImagePath = ""
        settingsStore.settings.breakBackgroundMode = .hills
    }

    private func isWorkingDaySelected(_ weekday: WorkingWeekday) -> Bool {
        settingsStore.settings.workingDays.contains(weekday.rawValue)
    }

    private func toggleWorkingDay(_ weekday: WorkingWeekday) {
        if settingsStore.settings.workingDays.contains(weekday.rawValue) {
            settingsStore.settings.workingDays.remove(weekday.rawValue)
        } else {
            settingsStore.settings.workingDays.insert(weekday.rawValue)
        }
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let detail: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.58))
            }

            content
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
