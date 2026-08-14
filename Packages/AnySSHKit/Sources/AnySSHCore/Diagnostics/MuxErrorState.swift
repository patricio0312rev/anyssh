public enum MuxErrorState: String, ErrorStateMember {
    case absent
    case protocolMismatch
    case attachTargetVanished
    case detachFailed

    public static let group = ErrorStateGroup.mux

    public var copy: ErrorStateCopy {
        switch self {
        case .absent:
            ErrorStateCopy(
                title: "No multiplexer on this host",
                body: "Neither tmux nor herdr is on the host's login shell PATH, so sessions end "
                    + "when the app suspends. Install tmux to keep work running.",
                recoveryLabel: "Dismiss"
            )
        case .protocolMismatch:
            ErrorStateCopy(
                title: "Herdr version not supported",
                body: "The herdr on this host speaks a protocol this app does not read. Update "
                    + "herdr on the host, or use its tmux sessions.",
                recoveryLabel: "Use tmux"
            )
        case .attachTargetVanished:
            ErrorStateCopy(
                title: "Session no longer exists",
                body: "The pane closed on the host before the app attached. Refresh to see what "
                    + "is still running.",
                recoveryLabel: "Refresh"
            )
        case .detachFailed:
            ErrorStateCopy(
                title: "Could not detach",
                body: "The detach keys were not sent. Check the connection and try again.",
                recoveryLabel: "Try Again"
            )
        }
    }

    public var owningPhase: Int {
        switch self {
        case .absent, .protocolMismatch: 39
        case .attachTargetVanished: 40
        case .detachFailed: 52
        }
    }
}
