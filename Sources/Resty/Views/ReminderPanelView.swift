import SwiftUI

struct ReminderPanelView: View {
    @ObservedObject var coordinator: BreakCoordinator
    @ObservedObject var settingsStore: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 18) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.16))
                        .frame(width: 58, height: 58)

                    Image(systemName: "eye.circle.fill")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(coordinator.headlineText)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(settingsStore.settings.customBreakMessage)
                        .font(.system(size: 19, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                }

                Spacer()
            }

            HStack(spacing: 12) {
                primaryActionButton("Begin break now") {
                    coordinator.startBreakNow()
                }

                secondaryActionButton("- 5 min") {
                    coordinator.extend(by: -5 * 60)
                }

                secondaryActionButton("- 1 min") {
                    coordinator.extend(by: -60)
                }

                secondaryActionButton("+ 1 min") {
                    coordinator.extend(by: 60)
                }

                secondaryActionButton("+ 5 min") {
                    coordinator.extend(by: 5 * 60)
                }

                secondaryActionButton("Skip this round") {
                    coordinator.skipBreak()
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 26)
        .frame(width: 820)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
    }

    private func primaryActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
                .background(.white.opacity(0.18))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func secondaryActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.white.opacity(0.08))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
