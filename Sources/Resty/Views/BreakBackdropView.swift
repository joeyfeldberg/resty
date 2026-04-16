import AppKit
import SwiftUI

struct BreakBackdropView: View {
    var body: some View {
        ZStack {
            if let image = BreakBackgroundImageLoader.defaultImage() {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.07, blue: 0.10),
                        Color(red: 0.11, green: 0.16, blue: 0.15)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.28),
                    Color.black.opacity(0.10),
                    Color.black.opacity(0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color(red: 1.00, green: 0.74, blue: 0.52).opacity(0.16),
                    Color.clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 520
            )
            .blendMode(.screen)
        }
        .ignoresSafeArea()
    }
}

enum BreakBackgroundImageLoader {
    static let defaultImageName = "default-break-background"

    static func defaultImage() -> NSImage? {
        guard let url = resourceURL(named: defaultImageName),
              let image = NSImage(contentsOf: url) else {
            return nil
        }
        return image
    }

    private static func resourceURL(named name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png") {
            return url
        }

        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Backgrounds") {
            return url
        }

        #if SWIFT_PACKAGE
        return Bundle.module.url(forResource: name, withExtension: "png")
            ?? Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Backgrounds")
        #else
        return Bundle(for: BreakBackgroundBundleSentinel.self).url(
            forResource: name,
            withExtension: "png",
            subdirectory: "Backgrounds"
        )
        #endif
    }
}

private final class BreakBackgroundBundleSentinel {}
