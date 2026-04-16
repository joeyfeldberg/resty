import XCTest
@testable import Resty

final class BreakBackgroundImageLoaderTests: XCTestCase {
    func testDefaultBreakBackgroundImageIsPackaged() {
        let image = BreakBackgroundImageLoader.defaultImage()

        XCTAssertNotNil(image)
        XCTAssertEqual(image?.isValid, true)
    }
}
