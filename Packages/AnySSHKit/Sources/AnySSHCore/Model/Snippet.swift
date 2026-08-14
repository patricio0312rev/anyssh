import Foundation

public struct Snippet: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public var title: String
    public var body: String

    public init(id: String = UUID().uuidString.lowercased(), title: String, body: String) {
        self.id = id
        self.title = title
        self.body = body
    }

    public var label: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? body : title
    }
}

public struct SnippetLibrary: Codable, Sendable {
    public static let schemaVersion = 1

    public var snippets: [Snippet]

    public init(snippets: [Snippet] = SnippetLibrary.starters) {
        self.snippets = snippets
    }

    public static let starters = [
        Snippet(title: "Git status", body: "git status -sb"),
        Snippet(title: "Recent commits", body: "git log --oneline -20"),
        Snippet(title: "Disk usage", body: "du -sh * | sort -h"),
        Snippet(title: "Follow logs", body: "docker compose logs -f --tail 100"),
        Snippet(title: "Listening ports", body: "lsof -nP -iTCP -sTCP:LISTEN"),
    ]
}
