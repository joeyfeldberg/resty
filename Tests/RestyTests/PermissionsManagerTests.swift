import XCTest
@testable import Resty

final class PermissionsManagerTests: XCTestCase {
    func testGatedPrivacyStatusIsAuthorizedWhenSystemReportsAccess() {
        XCTAssertEqual(
            PermissionsManager.gatedPrivacyStatus(isAuthorized: true, hasRequested: false),
            .authorized
        )
    }

    func testGatedPrivacyStatusIsNotDeterminedBeforeRequest() {
        XCTAssertEqual(
            PermissionsManager.gatedPrivacyStatus(isAuthorized: false, hasRequested: false),
            .notDetermined
        )
    }

    func testGatedPrivacyStatusIsDeniedAfterRequestWithoutAccess() {
        XCTAssertEqual(
            PermissionsManager.gatedPrivacyStatus(isAuthorized: false, hasRequested: true),
            .denied
        )
    }
}
