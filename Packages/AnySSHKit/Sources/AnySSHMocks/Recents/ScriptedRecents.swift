import AnySSHCore
import Foundation

public enum RecentsFixture: String, CaseIterable, Sendable {
    case allFourSources = "all-four-sources"
    case claudeOnly = "claude-only"
    case none = "none"
    case allDeleted = "all-deleted"

    public var directories: [RecentDirectory] {
        switch self {
        case .allFourSources:
            return [
                RecentDirectory(
                    path: "/Users/dev/src/anyssh",
                    sources: [.claude, .codex, .opencode],
                    lastUsed: Date(timeIntervalSince1970: 1_786_545_915.143)
                ),
                RecentDirectory(
                    path: "/Users/dev/src/terminal-android",
                    sources: [.cursor, .claude],
                    lastUsed: Date(timeIntervalSince1970: 1_786_540_000)
                ),
                RecentDirectory(
                    path: "/Users/dev/src/portfolio",
                    sources: [.opencode],
                    lastUsed: Date(timeIntervalSince1970: 1_786_530_000)
                ),
                RecentDirectory(
                    path: "/Users/dev/src/agentkit",
                    sources: [.cursor],
                    lastUsed: Date(timeIntervalSince1970: 1_786_520_000)
                ),
            ]
        case .claudeOnly:
            return [
                RecentDirectory(
                    path: "/Users/dev/src/anyssh",
                    sources: [.claude],
                    lastUsed: Date(timeIntervalSince1970: 1_786_545_915.143)
                )
            ]
        case .none, .allDeleted:
            return []
        }
    }
}

public struct ScriptedRecents: RecentDirectoriesProbe {
    private let value: [RecentDirectory]

    public init(fixture: RecentsFixture) {
        value = fixture.directories
    }

    public init(directories: [RecentDirectory]) {
        value = directories
    }

    public func list(limit: Int) async throws -> [RecentDirectory] {
        Array(value.prefix(max(0, limit)))
    }
}
