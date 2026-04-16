import XCTest
@testable import Resty

final class RestyIconTests: XCTestCase {
    func testLucideIconsLoadAsImages() {
        XCTAssertNotNil(RestyIcon.eye.nsImage().representations.first)
        XCTAssertNotNil(RestyIcon.eyeClosed.nsImage().representations.first)
        XCTAssertNotNil(RestyIcon.eyeOff.nsImage().representations.first)
    }
}
