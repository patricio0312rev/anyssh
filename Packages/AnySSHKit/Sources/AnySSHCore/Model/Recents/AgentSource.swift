public enum AgentSource: String, Hashable, Sendable, CaseIterable, Comparable {
    case claude
    case codex
    case cursor
    case opencode

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
