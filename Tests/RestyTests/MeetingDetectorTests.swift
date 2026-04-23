import XCTest
@testable import Resty

final class MeetingDetectorTests: XCTestCase {
    func testStatusPausesForSlackWhenInjectedMediaUsageIsActive() {
        let detector = MeetingDetector(
            mediaUsageDetector: StubMediaUsageDetector(isActive: true),
            frontmostApplicationProvider: {
                RunningApplicationContext(
                    bundleIdentifier: "com.tinyspeck.slackmacgap",
                    localizedName: "Slack"
                )
            },
            browserContextProvider: { nil },
            frontmostBrowserNameProvider: { nil }
        )

        XCTAssertEqual(
            detector.status(using: AppSettings()),
            DetectorStatus(isActive: true, reason: "Slack call active")
        )
    }

    func testStatusDoesNotPauseForSlackWhenInjectedMediaUsageIsInactive() {
        let detector = MeetingDetector(
            mediaUsageDetector: StubMediaUsageDetector(isActive: false),
            frontmostApplicationProvider: {
                RunningApplicationContext(
                    bundleIdentifier: "com.tinyspeck.slackmacgap",
                    localizedName: "Slack"
                )
            },
            browserContextProvider: { nil },
            frontmostBrowserNameProvider: { nil }
        )

        XCTAssertEqual(detector.status(using: AppSettings()), .inactive)
    }

    func testStatusPausesForBrowserWhenTabAutomationFailsButMediaUsageIsActive() {
        let detector = MeetingDetector(
            mediaUsageDetector: StubMediaUsageDetector(isActive: true),
            frontmostApplicationProvider: { nil },
            browserContextProvider: { nil },
            frontmostBrowserNameProvider: { "Firefox" }
        )

        XCTAssertEqual(
            detector.status(using: AppSettings()),
            DetectorStatus(isActive: true, reason: "Firefox using camera or mic")
        )
    }

    func testStatusSkipsMediaProbeWhenMeetingPauseIsDisabled() {
        let mediaUsageDetector = CountingMediaUsageDetector(isActive: true)
        var settings = AppSettings()
        settings.smartPauseMeetings = false
        let detector = MeetingDetector(
            mediaUsageDetector: mediaUsageDetector,
            frontmostApplicationProvider: {
                RunningApplicationContext(
                    bundleIdentifier: "com.tinyspeck.slackmacgap",
                    localizedName: "Slack"
                )
            },
            browserContextProvider: { nil },
            frontmostBrowserNameProvider: { nil }
        )

        XCTAssertEqual(detector.status(using: settings), .inactive)
        XCTAssertEqual(mediaUsageDetector.callCount, 0)
    }

    func testSlackDoesNotPauseWithoutMediaUsage() {
        let status = MeetingDetector.foregroundAppStatus(
            bundleIdentifier: "com.tinyspeck.slackmacgap",
            appName: "Slack",
            mediaDevicesInUse: false
        )

        XCTAssertEqual(status, .inactive)
    }

    func testSlackPausesWhenMediaDevicesAreInUse() {
        let status = MeetingDetector.foregroundAppStatus(
            bundleIdentifier: "com.tinyspeck.slackmacgap",
            appName: "Slack",
            mediaDevicesInUse: true
        )

        XCTAssertEqual(status, DetectorStatus(isActive: true, reason: "Slack call active"))
    }

    func testZoomStillPausesWhenFrontmost() {
        let status = MeetingDetector.foregroundAppStatus(
            bundleIdentifier: "us.zoom.xos",
            appName: "Zoom",
            mediaDevicesInUse: false
        )

        XCTAssertEqual(status, DetectorStatus(isActive: true, reason: "Zoom in foreground"))
    }

    func testFirefoxGoogleMeetPausesWhenMediaDevicesAreInUse() {
        let status = MeetingDetector.browserStatus(
            context: BrowserMediaContext(
                appName: "Firefox",
                title: "Google Meet",
                url: "https://meet.google.com/abc-defg-hij"
            ),
            frontmostBrowserName: "Firefox",
            mediaDevicesInUse: true
        )

        XCTAssertEqual(status, DetectorStatus(isActive: true, reason: "Browser meeting with camera or mic active"))
    }

    func testFirefoxMediaFallbackPausesWhenTabAutomationIsUnavailable() {
        let status = MeetingDetector.browserStatus(
            context: nil,
            frontmostBrowserName: "Firefox",
            mediaDevicesInUse: true
        )

        XCTAssertEqual(status, DetectorStatus(isActive: true, reason: "Firefox using camera or mic"))
    }

    func testFirefoxMediaFallbackDoesNotPauseWithoutMediaUsage() {
        let status = MeetingDetector.browserStatus(
            context: nil,
            frontmostBrowserName: "Firefox",
            mediaDevicesInUse: false
        )

        XCTAssertNil(status)
    }
}

private struct StubMediaUsageDetector: MediaUsageDetecting {
    let isActive: Bool

    func cameraOrMicrophoneInUse() -> Bool {
        isActive
    }
}

private final class CountingMediaUsageDetector: MediaUsageDetecting {
    private(set) var callCount = 0
    private let isActive: Bool

    init(isActive: Bool) {
        self.isActive = isActive
    }

    func cameraOrMicrophoneInUse() -> Bool {
        callCount += 1
        return isActive
    }
}
