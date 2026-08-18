public enum SessionTitleDisplayMode: String, CaseIterable, Codable, Hashable, Sendable {
    case sessionName
    case activeAgent
    case multiplexer
    case smart

    public var title: String {
        switch self {
        case .sessionName: "Session name"
        case .activeAgent: "Active agent"
        case .multiplexer: "Multiplexer"
        case .smart: "Smart title"
        }
    }
}
