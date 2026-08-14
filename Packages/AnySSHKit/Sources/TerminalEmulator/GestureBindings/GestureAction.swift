import AnySSHCore

public enum GestureAction: Hashable, Sendable {
    case chord(Chord)
    case multiplexer(String)
    case appCommand(String)

    public var label: String {
        switch self {
        case .chord(let chord): chord.label
        case .multiplexer(let name): name.replacingOccurrences(of: "_", with: " ").capitalized
        case .appCommand(let identifier): identifier
        }
    }
}

public struct ResolvedGestureAction: Hashable, Sendable {
    public let action: GestureAction?
    public let reason: String?

    public init(action: GestureAction?, reason: String? = nil) {
        self.action = action
        self.reason = reason
    }

    public static let unbound = ResolvedGestureAction(action: nil)
}

public enum GestureActionResolver {
    public static func resolve(
        _ action: GestureAction?,
        capabilities: HostCapabilities
    ) -> ResolvedGestureAction {
        guard let action else { return .unbound }
        guard case .multiplexer = action else { return ResolvedGestureAction(action: action) }
        guard capabilities.multiplexerErrorState == nil else {
            return ResolvedGestureAction(
                action: nil, reason: capabilities.multiplexerErrorState.map(String.init(describing:)))
        }
        return ResolvedGestureAction(action: action)
    }
}
