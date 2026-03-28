import SwiftUI

struct FloatingCountdownView: View {
    @ObservedObject var coordinator: BreakCoordinator

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)

            VStack(spacing: 0) {
                Text("\(coordinator.displayedBreakSeconds)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("sec")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                    .textCase(.uppercase)
            }
        }
        .frame(width: 68, height: 68)
        .shadow(color: .black.opacity(0.16), radius: 10, y: 4)
    }
}
