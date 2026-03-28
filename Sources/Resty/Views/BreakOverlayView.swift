import SwiftUI

struct BreakOverlayView: View {
    @ObservedObject var coordinator: BreakCoordinator
    @ObservedObject var settingsStore: SettingsStore

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VisualStyle.breakBackground
                .ignoresSafeArea()
                .overlay(
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { index in
                            Rectangle()
                                .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.06 : 0.03))
                                .rotationEffect(.degrees(12))
                                .offset(x: CGFloat(index * 20))
                        }
                    }
                )

            VStack(alignment: .leading, spacing: 20) {
                Text("Resty")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                Text(settingsStore.settings.customBreakMessage)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Break ends in \(Int(coordinator.timeRemainingInBreak.rounded(.up)))s")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))

                HStack(spacing: 12) {
                    if settingsStore.settings.allowEarlyEnd {
                        Button("End break early") {
                            coordinator.endBreakEarly()
                        }
                    }

                    Button("Skip next round") {
                        coordinator.skipBreak()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.black.opacity(0.6))
            }
            .padding(56)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.82))
                .frame(width: 300, height: 80)
                .overlay(
                    HStack(spacing: 14) {
                        Circle()
                            .fill(LinearGradient(colors: [.pink, .orange], startPoint: .bottomLeading, endPoint: .topTrailing))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "eyes")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.black.opacity(0.8))
                            )

                        Text("Reset for \(Int(coordinator.timeRemainingInBreak.rounded(.up)))")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                )
                .padding(34)
        }
    }
}
