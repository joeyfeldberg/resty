import AVFoundation
import AppKit
import ApplicationServices
import Combine
import CoreGraphics
import Foundation

enum PermissionStatus: String, Equatable {
    case authorized
    case notDetermined
    case denied
    case unavailable

    var label: String {
        switch self {
        case .authorized:
            return "Allowed"
        case .notDetermined:
            return "Not requested"
        case .denied:
            return "Needs access"
        case .unavailable:
            return "Unavailable"
        }
    }

    var actionTitle: String {
        switch self {
        case .authorized:
            return "Allowed"
        case .notDetermined:
            return "Allow"
        case .denied:
            return "Open Settings"
        case .unavailable:
            return "Unavailable"
        }
    }
}

@MainActor
final class PermissionsManager: ObservableObject {
    @Published private(set) var browserAutomationStatus: PermissionStatus = .notDetermined
    @Published private(set) var cameraStatus: PermissionStatus = .notDetermined
    @Published private(set) var microphoneStatus: PermissionStatus = .notDetermined
    @Published private(set) var screenRecordingStatus: PermissionStatus = .notDetermined
    @Published private(set) var accessibilityStatus: PermissionStatus = .notDetermined
    @Published private(set) var browserAutomationTargetName: String = "Browser"

    private let defaults: UserDefaults
    private let browserAutomationStatusKey = "resty.permissions.browserAutomation"
    private let screenRecordingRequestedKey = "resty.permissions.screenRecordingRequested"
    private let accessibilityRequestedKey = "resty.permissions.accessibilityRequested"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        refreshStatuses()
    }

    func refreshStatuses() {
        cameraStatus = permissionStatus(from: AVCaptureDevice.authorizationStatus(for: .video))
        microphoneStatus = permissionStatus(from: AVCaptureDevice.authorizationStatus(for: .audio))
        screenRecordingStatus = Self.gatedPrivacyStatus(
            isAuthorized: CGPreflightScreenCaptureAccess(),
            hasRequested: defaults.bool(forKey: screenRecordingRequestedKey)
        )
        accessibilityStatus = Self.gatedPrivacyStatus(
            isAuthorized: AXIsProcessTrusted(),
            hasRequested: defaults.bool(forKey: accessibilityRequestedKey)
        )

        if let target = browserAutomationTarget() {
            browserAutomationTargetName = target.name
            browserAutomationStatus = cachedBrowserAutomationStatus()
        } else {
            browserAutomationTargetName = "Browser"
            browserAutomationStatus = .unavailable
        }
    }

    func requestCameraAccess() {
        handleAVRequest(for: .video)
    }

    func requestMicrophoneAccess() {
        handleAVRequest(for: .audio)
    }

    func requestScreenRecordingAccess() {
        defaults.set(true, forKey: screenRecordingRequestedKey)

        if screenRecordingStatus == .denied {
            openPrivacySettings(anchor: "Privacy_ScreenCapture")
            return
        }

        _ = CGRequestScreenCaptureAccess()
        refreshStatuses()
    }

    func requestAccessibilityAccess() {
        defaults.set(true, forKey: accessibilityRequestedKey)

        if accessibilityStatus == .denied {
            openPrivacySettings(anchor: "Privacy_Accessibility")
            return
        }

        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        refreshStatuses()
    }

    func requestBrowserAutomationAccess() {
        guard let target = browserAutomationTarget() else {
            refreshStatuses()
            return
        }

        if browserAutomationStatus == .denied {
            openPrivacySettings(anchor: "Privacy_Automation")
            return
        }

        let script = browserAutomationProbeScript(for: target)
        let result = AppleScriptRunner.runDetailed(script)
        if result.errorCode == nil {
            defaults.set(PermissionStatus.authorized.rawValue, forKey: browserAutomationStatusKey)
        } else if result.errorCode == -1743 {
            defaults.set(PermissionStatus.denied.rawValue, forKey: browserAutomationStatusKey)
        }
        refreshStatuses()
    }

    private func handleAVRequest(for mediaType: AVMediaType) {
        let status = AVCaptureDevice.authorizationStatus(for: mediaType)
        if status == .denied || status == .restricted {
            let anchor = mediaType == .video ? "Privacy_Camera" : "Privacy_Microphone"
            openPrivacySettings(anchor: anchor)
            refreshStatuses()
            return
        }

        AVCaptureDevice.requestAccess(for: mediaType) { _ in
            Task { @MainActor in
                self.refreshStatuses()
            }
        }
    }

    private func permissionStatus(from status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    nonisolated static func gatedPrivacyStatus(isAuthorized: Bool, hasRequested: Bool) -> PermissionStatus {
        if isAuthorized {
            return .authorized
        }

        return hasRequested ? .denied : .notDetermined
    }

    private func cachedBrowserAutomationStatus() -> PermissionStatus {
        guard let rawValue = defaults.string(forKey: browserAutomationStatusKey),
              let status = PermissionStatus(rawValue: rawValue) else {
            return .notDetermined
        }
        return status
    }

    private func browserAutomationTarget() -> BrowserAutomationTarget? {
        let installedBundleIdentifiers = Set(
            BrowserAutomationPermissionHelper.supportedTargets.compactMap { target in
                NSWorkspace.shared.urlForApplication(withBundleIdentifier: target.bundleIdentifier) != nil
                    ? target.bundleIdentifier
                    : nil
            }
        )

        return BrowserAutomationPermissionHelper.preferredTarget(
            frontmostBundleIdentifier: NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            installedBundleIdentifiers: installedBundleIdentifiers
        )
    }

    private func browserAutomationProbeScript(for target: BrowserAutomationTarget) -> String {
        if target.scriptName == "Safari" {
            return """
            tell application "Safari"
                if (count of windows) is 0 then return ""
                return name of front document
            end tell
            """
        }

        if target.scriptName == "Firefox" {
            return """
            tell application "Firefox"
                if (count of windows) is 0 then return ""
                return name of front window
            end tell
            """
        }

        return """
        tell application "\(target.scriptName)"
            if (count of windows) is 0 then return ""
            return title of active tab of front window
        end tell
        """
    }

    private func openPrivacySettings(anchor: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") {
            NSWorkspace.shared.open(url)
        }
    }
}
