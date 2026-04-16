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

    func testPrefersFrontmostFirefoxWhenInstalled() {
        let target = BrowserAutomationPermissionHelper.preferredTarget(
            frontmostBundleIdentifier: "org.mozilla.firefox",
            installedBundleIdentifiers: ["com.apple.Safari", "org.mozilla.firefox"]
        )

        XCTAssertEqual(target?.bundleIdentifier, "org.mozilla.firefox")
    }

    func testFallsBackToFirstInstalledSupportedBrowser() {
        let target = BrowserAutomationPermissionHelper.preferredTarget(
            frontmostBundleIdentifier: "com.apple.dt.Xcode",
            installedBundleIdentifiers: ["com.apple.Safari", "com.google.Chrome"]
        )

        XCTAssertEqual(target?.bundleIdentifier, "com.apple.Safari")
    }
}
