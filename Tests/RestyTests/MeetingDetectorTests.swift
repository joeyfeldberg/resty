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
}
