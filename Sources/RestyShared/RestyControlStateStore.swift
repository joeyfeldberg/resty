import Foundation

public enum RestyControlCommandKind: String, Codable, Equatable, Sendable {
    case pause
    case resume
    case startBreak
    case skipRound
}

public struct RestyControlCommand: Codable, Equatable, Sendable {
    public var id: UUID
    public var kind: RestyControlCommandKind
    public var issuedAt: Date

    public init(id: UUID = UUID(), kind: RestyControlCommandKind, issuedAt: Date = Date()) {
        self.id = id
        self.kind = kind
        self.issuedAt = issuedAt
    }
}

public struct RestyControlSnapshot: Codable, Equatable, Sendable {
    public var isRemindersActive: Bool
    public var statusText: String
    public var updatedAt: Date
    public var lastHandledCommandID: UUID?

    public init(
        isRemindersActive: Bool = true,
        statusText: String = "Resty",
        updatedAt: Date = Date(),
        lastHandledCommandID: UUID? = nil
    ) {
        self.isRemindersActive = isRemindersActive
        self.statusText = statusText
        self.updatedAt = updatedAt
        self.lastHandledCommandID = lastHandledCommandID
    }
}

public struct RestyControlStateStore {
    public static let suiteName = "local.resty.controls"
    private static let snapshotKey = "resty.controls.snapshot"
    private static let pendingCommandKey = "resty.controls.pendingCommand"

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults = UserDefaults(suiteName: Self.suiteName) ?? .standard) {
        self.defaults = defaults
    }

    public func snapshot() -> RestyControlSnapshot {
        guard let data = defaults.data(forKey: Self.snapshotKey),
              let snapshot = try? decoder.decode(RestyControlSnapshot.self, from: data) else {
            return RestyControlSnapshot()
        }

        return snapshot
    }

    public func saveSnapshot(_ snapshot: RestyControlSnapshot) {
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: Self.snapshotKey)
    }

    public func writeCommand(_ command: RestyControlCommand) {
        guard let data = try? encoder.encode(command) else { return }
        defaults.set(data, forKey: Self.pendingCommandKey)
    }

    public func pendingCommand() -> RestyControlCommand? {
        guard let data = defaults.data(forKey: Self.pendingCommandKey),
              let command = try? decoder.decode(RestyControlCommand.self, from: data) else {
            return nil
        }

        return command
    }

    public func markCommandHandled(_ command: RestyControlCommand, snapshot: RestyControlSnapshot) {
        var updatedSnapshot = snapshot
        updatedSnapshot.lastHandledCommandID = command.id
        updatedSnapshot.updatedAt = Date()
        saveSnapshot(updatedSnapshot)
        defaults.removeObject(forKey: Self.pendingCommandKey)
    }
}
