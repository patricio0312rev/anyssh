public enum ReachabilityPresentation: String, CaseIterable, Sendable {
    case checking
    case reachable
    case unreachable
    case unknown

    public init(_ reachability: Reachability) {
        switch reachability {
        case .reachable: self = .reachable
        case .unreachable: self = .unreachable
        case .unknown: self = .unknown
        }
    }

    public var accessibilityLabel: String {
        switch self {
        case .checking: "Checking reachability"
        case .reachable: "Host reachable"
        case .unreachable: "Host unreachable"
        case .unknown: "Reachability unknown"
        }
    }

    public var symbolName: String {
        switch self {
        case .checking: "circle.dotted"
        case .reachable: "checkmark.circle.fill"
        case .unreachable: "xmark.circle.fill"
        case .unknown: "questionmark.circle.fill"
        }
    }
}
