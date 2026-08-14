public enum SessionErrorState: String, ErrorStateMember {
    case survivalSSH
    case survivalMultiplexed
    case survivalRoaming
    case reattached
    case reconnectExhausted

    public static let group = ErrorStateGroup.session

    public var copy: ErrorStateCopy {
        switch self {
        case .survivalSSH:
            ErrorStateCopy(
                title: "Session ends on sleep",
                body: "Backgrounding ends this session. Work continues on the host only if it is "
                    + "inside tmux or herdr.",
                recoveryLabel: "Reconnect"
            )
        case .survivalMultiplexed:
            ErrorStateCopy(
                title: "Reattaches on return",
                body: "Reattaches on return. Scrollback is preserved on the host.",
                recoveryLabel: "Reattach"
            )
        case .survivalRoaming:
            ErrorStateCopy(
                title: "Survives sleep and roam",
                body: "Survives sleep and network change. Scrollback from before the drop is lost "
                    + "unless you are in a multiplexer.",
                recoveryLabel: "Reconnect"
            )
        case .reattached:
            ErrorStateCopy(
                title: "Reattached",
                body: "The session is connected again.",
                recoveryLabel: "Dismiss"
            )
        case .reconnectExhausted:
            ErrorStateCopy(
                title: "Could not reconnect",
                body: "Every automatic attempt failed. Tap Reconnect to try once more.",
                recoveryLabel: "Reconnect"
            )
        }
    }

    public var owningPhase: Int { 21 }
}
