import XCTest
@testable import Resty

final class MeetingDetectorTests: XCTestCase {
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
