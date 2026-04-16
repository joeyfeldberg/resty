import AVFoundation
import AppKit
import CoreGraphics
import Foundation

protocol ActivityDetector {
    var isEnabled: Bool { get }
    func status(using settings: AppSettings) -> DetectorStatus
}

struct DetectorStatus: Equatable {
    var isActive: Bool
    var reason: String?

    static let inactive = DetectorStatus(isActive: false, reason: nil)
}

struct BrowserMediaContext {
    let appName: String
    let title: String
    let url: String

    var normalizedTitle: String { title.lowercased() }
    var normalizedURL: String { url.lowercased() }

    func matches(any patterns: Set<String>) -> Bool {
        let haystack = "\(normalizedTitle) \(normalizedURL)"
        return patterns.contains { haystack.contains($0) }
    }
}

enum BrowserMediaInspector {
    private struct SupportedBrowser {
        let name: String
        let bundleIdentifier: String
        let scriptName: String
    }

    private static let supportedApps: [SupportedBrowser] = [
        SupportedBrowser(name: "Google Chrome", bundleIdentifier: "com.google.Chrome", scriptName: "Google Chrome"),
        SupportedBrowser(name: "Arc", bundleIdentifier: "company.thebrowser.Browser", scriptName: "Arc"),
        SupportedBrowser(name: "Microsoft Edge", bundleIdentifier: "com.microsoft.edgemac", scriptName: "Microsoft Edge"),
        SupportedBrowser(name: "Safari", bundleIdentifier: "com.apple.Safari", scriptName: "Safari"),
        SupportedBrowser(name: "Firefox", bundleIdentifier: "org.mozilla.firefox", scriptName: "Firefox")
    ]

    static func frontmostContext() -> BrowserMediaContext? {
        guard let app = frontmostBrowserApp() else {
            return nil
        }

        let scriptSource: String
        if app.scriptName == "Safari" {
            scriptSource = """
            tell application "Safari"
                if not (exists front document) then return ""
                set currentTab to current tab of front window
                return (name of currentTab) & "||" & (URL of currentTab)
            end tell
            """
        } else if app.scriptName == "Firefox" {
            scriptSource = """
            tell application "Firefox"
                if (count of windows) is 0 then return ""
                return (name of front window) & "||"
            end tell
            """
        } else {
            scriptSource = """
            tell application "\(app.scriptName)"
                if (count of windows) is 0 then return ""
                set currentTab to active tab of front window
                return (title of currentTab) & "||" & (URL of currentTab)
            end tell
            """
        }

        guard let result = AppleScriptRunner.run(scriptSource),
              !result.isEmpty else {
            return nil
        }

        let parts = result.components(separatedBy: "||")
        let title = parts.first ?? ""
        let url = parts.count > 1 ? parts[1] : ""
        return BrowserMediaContext(appName: app.name, title: title, url: url)
    }

    static func frontmostBrowserName() -> String? {
        frontmostBrowserApp()?.name
    }

    private static func frontmostBrowserApp() -> SupportedBrowser? {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        return supportedApps.first { browser in
            browser.bundleIdentifier == frontmost.bundleIdentifier
                || browser.name == frontmost.localizedName
        }
    }
}

enum AppleScriptRunner {
    static func run(_ source: String) -> String? {
        let result = runDetailed(source)
        return result.output
    }

    static func runDetailed(_ source: String) -> AppleScriptResult {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            return AppleScriptResult(output: nil, errorCode: nil)
        }
        let output = script.executeAndReturnError(&error)
        let code = error?[NSAppleScript.errorNumber] as? Int
        return AppleScriptResult(
            output: error == nil ? output.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            errorCode: code
        )
    }
}

struct AppleScriptResult {
    let output: String?
    let errorCode: Int?
}

enum BrowserAutomationPermissionHelper {
    static let supportedTargets: [BrowserAutomationTarget] = [
        BrowserAutomationTarget(name: "Safari", bundleIdentifier: "com.apple.Safari", scriptName: "Safari"),
        BrowserAutomationTarget(name: "Google Chrome", bundleIdentifier: "com.google.Chrome", scriptName: "Google Chrome"),
        BrowserAutomationTarget(name: "Arc", bundleIdentifier: "company.thebrowser.Browser", scriptName: "Arc"),
        BrowserAutomationTarget(name: "Microsoft Edge", bundleIdentifier: "com.microsoft.edgemac", scriptName: "Microsoft Edge"),
        BrowserAutomationTarget(name: "Firefox", bundleIdentifier: "org.mozilla.firefox", scriptName: "Firefox")
    ]

    static func preferredTarget(frontmostBundleIdentifier: String?, installedBundleIdentifiers: Set<String>) -> BrowserAutomationTarget? {
        if let frontmostBundleIdentifier,
           let frontmostTarget = supportedTargets.first(where: { $0.bundleIdentifier == frontmostBundleIdentifier }),
           installedBundleIdentifiers.contains(frontmostBundleIdentifier) {
            return frontmostTarget
        }

        return supportedTargets.first(where: { installedBundleIdentifiers.contains($0.bundleIdentifier) })
    }
}

struct BrowserAutomationTarget: Equatable {
    let name: String
    let bundleIdentifier: String
    let scriptName: String
}

struct MeetingDetector: ActivityDetector {
    private let meetingBundleIdentifiers: Set<String> = [
        "us.zoom.xos",
        "com.microsoft.teams2",
        "com.microsoft.teams",
        "com.hnc.Discord",
        "com.cisco.webexmeetingsapp",
        "com.tinyspeck.slackmacgap",
        "com.apple.FaceTime"
    ]

    static let mediaRequiredBundleIdentifiers: Set<String> = [
        "com.microsoft.teams2",
        "com.microsoft.teams",
        "com.hnc.Discord",
        "com.tinyspeck.slackmacgap"
    ]

    var isEnabled: Bool = true

    func status(using settings: AppSettings) -> DetectorStatus {
        guard isEnabled, settings.smartPauseMeetings else { return .inactive }
        let mediaDevicesInUse = mediaDevicesInUse()

        if let app = NSWorkspace.shared.frontmostApplication,
           let bundleIdentifier = app.bundleIdentifier,
           meetingBundleIdentifiers.contains(bundleIdentifier) {
            return Self.foregroundAppStatus(
                bundleIdentifier: bundleIdentifier,
                appName: app.localizedName ?? "Meeting app",
                mediaDevicesInUse: mediaDevicesInUse
            )
        }

        if let browserContext = BrowserMediaInspector.frontmostContext(),
           let status = Self.browserStatus(
            context: browserContext,
            frontmostBrowserName: browserContext.appName,
            mediaDevicesInUse: mediaDevicesInUse
           ) {
            return status
        }

        if let status = Self.browserStatus(
            context: nil,
            frontmostBrowserName: BrowserMediaInspector.frontmostBrowserName(),
            mediaDevicesInUse: mediaDevicesInUse
        ) {
            return status
        }

        return .inactive
    }

    private func mediaDevicesInUse() -> Bool {
        if #available(macOS 14.0, *) {
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .external, .microphone],
                mediaType: nil,
                position: .unspecified
            )
            return discoverySession.devices.contains { $0.isInUseByAnotherApplication }
        }

        let videoDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        ).devices
        let audioDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInMicrophone],
            mediaType: .audio,
            position: .unspecified
        ).devices
        return (videoDevices + audioDevices).contains { $0.isInUseByAnotherApplication }
    }

    static func foregroundAppStatus(bundleIdentifier: String, appName: String, mediaDevicesInUse: Bool) -> DetectorStatus {
        if mediaRequiredBundleIdentifiers.contains(bundleIdentifier) {
            guard mediaDevicesInUse else { return .inactive }
            return DetectorStatus(isActive: true, reason: "\(appName) call active")
        }

        if mediaDevicesInUse {
            return DetectorStatus(isActive: true, reason: "\(appName) call active")
        }

        return DetectorStatus(isActive: true, reason: "\(appName) in foreground")
    }

    static func browserStatus(
        context: BrowserMediaContext?,
        frontmostBrowserName: String?,
        mediaDevicesInUse: Bool
    ) -> DetectorStatus? {
        if let context, context.matches(any: DetectionPatterns.meeting) {
            if mediaDevicesInUse {
                return DetectorStatus(isActive: true, reason: "Browser meeting with camera or mic active")
            }

            return DetectorStatus(isActive: true, reason: "Meeting tab open in \(context.appName)")
        }

        guard mediaDevicesInUse, let frontmostBrowserName else {
            return nil
        }

        return DetectorStatus(isActive: true, reason: "\(frontmostBrowserName) using camera or mic")
    }
}

struct VideoPlaybackDetector: ActivityDetector {
    private let videoBundleIdentifiers: Set<String> = [
        "com.colliderli.iina",
        "com.colliderli.IINA",
        "com.apple.TV",
        "org.videolan.vlc",
        "com.apple.QuickTimePlayerX"
    ]

    var isEnabled: Bool = true

    func status(using settings: AppSettings) -> DetectorStatus {
        guard isEnabled, settings.smartPauseVideoPlayback else { return .inactive }
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return .inactive
        }

        if let bundleIdentifier = app.bundleIdentifier,
           videoBundleIdentifiers.contains(bundleIdentifier) {
            return DetectorStatus(isActive: true, reason: "\(app.localizedName ?? "Video app") playback detected")
        }

        if let browserContext = BrowserMediaInspector.frontmostContext(),
           browserContext.matches(any: DetectionPatterns.video),
           !browserContext.matches(any: DetectionPatterns.meeting) {
            return DetectorStatus(isActive: true, reason: "Video tab active in \(browserContext.appName)")
        }

        return .inactive
    }
}

struct FullscreenDetector: ActivityDetector {
    var isEnabled: Bool = true

    func status(using settings: AppSettings) -> DetectorStatus {
        guard isEnabled, settings.smartPauseFullscreen else { return .inactive }
        guard let frontmost = NSWorkspace.shared.frontmostApplication?.localizedName else {
            return .inactive
        }

        let options = CGWindowListOption(arrayLiteral: [.optionOnScreenOnly, .excludeDesktopElements])
        guard let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]],
              let screen = NSScreen.main else {
            return .inactive
        }

        let screenFrame = screen.frame.integral
        for info in infoList {
            guard let ownerName = info[kCGWindowOwnerName as String] as? String,
                  ownerName == frontmost,
                  let boundsAny = info[kCGWindowBounds as String],
                  let bounds = CGRect(dictionaryRepresentation: boundsAny as! CFDictionary) else {
                continue
            }

            if bounds.width >= screenFrame.width - 8, bounds.height >= screenFrame.height - 8 {
                return DetectorStatus(isActive: true, reason: "\(frontmost) is fullscreen")
            }
        }

        return .inactive
    }
}

struct ScreenCaptureDetector: ActivityDetector {
    var isEnabled: Bool = true

    func status(using settings: AppSettings) -> DetectorStatus {
        guard isEnabled, settings.smartPauseScreenCapture else { return .inactive }
        guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return .inactive
        }

        let captureApps = ["QuickTime Player", "CleanShot X", "Loom", "Kap", "Screen Studio"]
        let ownerNames = Set(windows.compactMap { $0[kCGWindowOwnerName as String] as? String })
        if let captureApp = captureApps.first(where: ownerNames.contains) {
            return DetectorStatus(isActive: true, reason: "\(captureApp) screen capture active")
        }

        return .inactive
    }
}

struct FocusAppDetector: ActivityDetector {
    var isEnabled: Bool = true

    func status(using settings: AppSettings) -> DetectorStatus {
        guard isEnabled, settings.smartPauseFocusApps else { return .inactive }
        guard let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
              settings.focusBundleIdentifiers.contains(bundleIdentifier) else {
            return .inactive
        }

        return DetectorStatus(isActive: true, reason: "Focused work app in foreground")
    }
}
