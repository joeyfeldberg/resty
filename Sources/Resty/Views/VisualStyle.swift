import SwiftUI

enum VisualStyle {
    static let panelBackground = LinearGradient(
        colors: [Color(red: 0.10, green: 0.11, blue: 0.22), Color(red: 0.10, green: 0.11, blue: 0.18)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let buttonFill = Color.white.opacity(0.08)
    static let secondaryText = Color.white.opacity(0.70)
    static let border = Color.white.opacity(0.08)

    static let breakBackground = LinearGradient(
        colors: [
            Color(red: 0.10, green: 0.05, blue: 0.28),
            Color(red: 0.14, green: 0.20, blue: 0.70),
            Color(red: 0.74, green: 0.84, blue: 0.64),
            Color(red: 0.15, green: 0.09, blue: 0.55)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let settingsBackground = LinearGradient(
        colors: [Color(red: 0.12, green: 0.13, blue: 0.16), Color(red: 0.09, green: 0.10, blue: 0.13)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
