import XCTest
@testable import RestyShared

final class RestyControlStateStoreTests: XCTestCase {
    func testCommandRoundTripAndHandledSnapshot() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = RestyControlStateStore(defaults: defaults)

        let command = RestyControlCommand(kind: .pause)
        store.writeCommand(command)

        XCTAssertEqual(store.pendingCommand(), command)

        store.markCommandHandled(
            command,
            snapshot: RestyControlSnapshot(isRemindersActive: false, statusText: "Paused")
        )

        XCTAssertNil(store.pendingCommand())
        XCTAssertEqual(store.snapshot().lastHandledCommandID, command.id)
        XCTAssertFalse(store.snapshot().isRemindersActive)
    }
}
