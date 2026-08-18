public enum SessionTitleDisplayMode: String, CaseIterable, Codable, Hashable, Sendable {
    case sessionName
    case agentSession
    case activeAgent
    case multiplexer
    case smart

    public var title: String {
        switch self {
        case .sessionName: "Session name"
        case .agentSession: "Agent session"
        case .activeAgent: "Active agent"
        case .multiplexer: "Multiplexer"
        case .smart: "Smart title"
        }
    }

    public var summary: String {
        switch self {
        case .sessionName: "The host you opened"
        case .agentSession: "The title the agent publishes"
        case .activeAgent: "Claude, Codex, OpenCode, and others"
        case .multiplexer: "herdr or tmux"
        case .smart: "The agent session, then the best fallback"
        }
    }
}
