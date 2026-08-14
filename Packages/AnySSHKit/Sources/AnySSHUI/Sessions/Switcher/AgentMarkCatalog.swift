enum AgentMarkCatalog {
    private static let marks: Set<String> = [
        "claude-code",
        "codex",
        "gemini",
        "grok-code",
        "opencode",
        "antigravity",
        "pi",
        "tmux",
        "herdr",
    ]

    static func hasMark(for id: String) -> Bool {
        marks.contains(id)
    }

    static func assetName(for id: String) -> String {
        "AgentMarks/\(id)"
    }

    static func fillsTile(_ id: String) -> Bool {
        id == "herdr"
    }
}
