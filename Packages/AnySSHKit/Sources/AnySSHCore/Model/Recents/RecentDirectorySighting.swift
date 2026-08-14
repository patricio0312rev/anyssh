import Foundation

public struct RecentDirectorySighting: Hashable, Sendable {
    public let path: String
    public let source: AgentSource
    public let lastUsed: Date

    public init(path: String, source: AgentSource, lastUsed: Date) {
        self.path = path
        self.source = source
        self.lastUsed = lastUsed
    }
}
