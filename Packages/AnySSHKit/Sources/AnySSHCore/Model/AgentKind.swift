public struct AgentKind: Hashable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let monogram: String
    public let accentToken: String
    public let aliases: [String]

    public init(id: String, name: String, monogram: String, accentToken: String, aliases: [String]) {
        self.id = id
        self.name = name
        self.monogram = monogram
        self.accentToken = accentToken
        self.aliases = aliases
    }
}

public enum AgentKindCatalog {
    public static let kinds = [
        AgentKind(
            id: "claude-code", name: "Claude Code", monogram: "C", accentToken: "statusAttention",
            aliases: ["claude", "claude code"]),
        AgentKind(id: "codex", name: "Codex", monogram: "CX", accentToken: "textPrimary", aliases: ["codex"]),
        AgentKind(
            id: "opencode", name: "opencode", monogram: "O", accentToken: "textPrimary", aliases: ["opencode"]
        ),
        AgentKind(id: "pi", name: "Pi", monogram: "P", accentToken: "textPrimary", aliases: ["pi"]),
        AgentKind(
            id: "grok-code", name: "Grok Code", monogram: "G", accentToken: "textPrimary",
            aliases: ["grok", "grok code"]),
        AgentKind(
            id: "antigravity", name: "Antigravity", monogram: "A", accentToken: "textPrimary",
            aliases: ["antigravity"]),
        AgentKind(
            id: "gemini", name: "Gemini", monogram: "G", accentToken: "textPrimary", aliases: ["gemini"]),
        AgentKind(
            id: "hermes", name: "Hermes", monogram: "H", accentToken: "textPrimary", aliases: ["hermes"]),
        AgentKind(
            id: "openclaw", name: "OpenClaw", monogram: "OC", accentToken: "textPrimary",
            aliases: ["openclaw", "open claw"]),
        AgentKind(id: "herdr", name: "herdr", monogram: "H", accentToken: "textPrimary", aliases: ["herdr"]),
        AgentKind(id: "tmux", name: "tmux", monogram: "T", accentToken: "textPrimary", aliases: ["tmux"]),
    ]

    public static let multiplexerIDs: Set<String> = ["herdr", "tmux"]
}

extension AgentKind {
    public var isMultiplexer: Bool {
        AgentKindCatalog.multiplexerIDs.contains(id)
    }
}
