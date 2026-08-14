import AnySSHCore

public enum SessionReconnectState: Hashable, Sendable {
    case idle
    case establishing
    case live
    case retrying(attempt: Int)
    case resumable
    case reconnectable
    case closed
    case failed(stateID: String)

    public static func derived(
        from state: TransportState,
        capabilities: TransportCapabilities
    ) -> Self {
        switch state {
        case .idle:
            .idle
        case .connecting, .authenticating:
            .establishing
        case .connected:
            .live
        case .reconnecting(let attempt):
            .retrying(attempt: attempt)
        case .disconnected(let reason):
            afterDisconnect(reason, capabilities: capabilities)
        }
    }

    public var offersReconnect: Bool {
        switch self {
        case .resumable, .reconnectable, .failed:
            true
        case .idle, .establishing, .live, .retrying, .closed:
            false
        }
    }

    public var isLive: Bool {
        self == .live
    }

    private static func afterDisconnect(
        _ reason: DisconnectReason,
        capabilities: TransportCapabilities
    ) -> Self {
        switch reason {
        case .closedByUser:
            .closed
        case .closedByRemote:
            .reconnectable
        case .backgrounded, .cancelledBySwitch:
            capabilities.serverSideResume ? .resumable : .reconnectable
        case .failed(let stateID):
            .failed(stateID: stateID)
        }
    }
}
