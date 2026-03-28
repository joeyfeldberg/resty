import XCTest
@testable import Resty

final class BrowserAutomationPermissionTests: XCTestCase {
    func testPrefersFrontmostSupportedBrowser() {
        let target = BrowserAutomationPermissionHelper.preferredTarget(
            frontmostBundleIdentifier: "com.google.Chrome",
            installedBundleIdentifiers: ["com.apple.Safari", "com.google.Chrome"]
        )

        XCTAssertEqual(target?.bundleIdentifier, "com.google.Chrome")
    }

    func testFallsBackToFirstInstalledSupportedBrowser() {
        let target = BrowserAutomationPermissionHelper.preferredTarget(
            frontmostBundleIdentifier: "com.apple.dt.Xcode",
            installedBundleIdentifiers: ["com.apple.Safari", "com.google.Chrome"]
        )

        XCTAssertEqual(target?.bundleIdentifier, "com.apple.Safari")
    }
}
