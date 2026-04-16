import AppKit
import SwiftUI

enum RestyIcon: String, Equatable {
    case eye = "eye"
    case eyeClosed = "eye-closed"
    case eyeOff = "eye-off"

    var accessibilityDescription: String {
        switch self {
        case .eye:
            return "Open eye"
        case .eyeClosed:
            return "Closed eye"
        case .eyeOff:
            return "Disabled eye"
        }
    }

    var fileName: String { rawValue }

    func nsImage() -> NSImage {
        let image = RestyIconLoader.image(named: fileName)
            ?? NSImage(systemSymbolName: fallbackSymbolName, accessibilityDescription: accessibilityDescription)
            ?? NSImage(size: NSSize(width: 24, height: 24))
        image.isTemplate = true
        return image
    }

    private var fallbackSymbolName: String {
        switch self {
        case .eye:
            return "eye"
        case .eyeClosed:
            return "eye.slash"
        case .eyeOff:
            return "eye.slash"
        }
    }
}

struct RestyIconImage: View {
    let icon: RestyIcon
    let size: CGFloat

    var body: some View {
        Image(nsImage: icon.nsImage())
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

enum RestyIconLoader {
    static func image(named name: String) -> NSImage? {
        guard let url = resourceURL(named: name),
              let image = NSImage(contentsOf: url) else {
            return nil
        }
        image.isTemplate = true
        return image
    }

    private static func resourceURL(named name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: "svg", subdirectory: "Lucide") {
            return url
        }

        #if SWIFT_PACKAGE
        return Bundle.module.url(forResource: name, withExtension: "svg", subdirectory: "Lucide")
        #else
        return Bundle(for: BundleSentinel.self).url(forResource: name, withExtension: "svg", subdirectory: "Lucide")
        #endif
    }
}

private final class BundleSentinel {}
