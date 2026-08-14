import Foundation

public struct RecentDirectory: Hashable, Sendable, Identifiable {
    public var id: String { path }
    public let path: String
    public let sources: [AgentSource]
    public let lastUsed: Date

    public init(path: String, sources: [AgentSource], lastUsed: Date) {
        self.path = path
        self.sources = sources
        self.lastUsed = lastUsed
    }

    public var basename: String {
        if path == "/" { return "/" }
        let trimmed = path.hasSuffix("/") ? String(path.dropLast()) : path
        return trimmed.split(separator: "/").last.map(String.init) ?? path
    }
}
