public enum MuxPollCadence: Sendable {
    public static let visible: Duration = .seconds(1)
    public static let background: Duration = .seconds(5)

    public static func interval(for visibility: MuxPollVisibility) -> Duration? {
        switch visibility {
        case .visible: visible
        case .background: background
        case .suspended: nil
        }
    }
}

public enum MuxPollVisibility: String, CaseIterable, Sendable {
    case visible
    case background
    case suspended
}
