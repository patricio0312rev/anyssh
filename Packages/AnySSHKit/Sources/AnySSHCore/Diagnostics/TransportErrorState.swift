public enum TransportErrorState: String, ErrorStateMember {
    case connectionRefused
    case hostUnreachable
    case dnsFallback
    case tailscaleSSH
    case keepaliveTimeout
    case cancelledBySwitch

    public static let group = ErrorStateGroup.transport

    public var copy: ErrorStateCopy {
        switch self {
        case .connectionRefused:
            ErrorStateCopy(
                title: "Connection refused",
                body: "Nothing is listening on that port. Check the port and that sshd runs on the host.",
                recoveryLabel: "Edit Host"
            )
        case .hostUnreachable:
            ErrorStateCopy(
                title: "Host unreachable",
                body: "No route to this host. Check that Tailscale is connected and the host is awake.",
                recoveryLabel: "Try Again"
            )
        case .dnsFallback:
            ErrorStateCopy(
                title: "Name lookup failed",
                body: "The hostname did not resolve. This connection used the last known Tailscale "
                    + "address instead.",
                recoveryLabel: "Edit Host"
            )
        case .tailscaleSSH:
            ErrorStateCopy(
                title: "Tailscale SSH host",
                body: "This host authenticates through Tailscale rather than with a key or a "
                    + "password. Connect as a user your Tailscale policy allows.",
                recoveryLabel: "Connect"
            )
        case .keepaliveTimeout:
            ErrorStateCopy(
                title: "Connection timed out",
                body: "The host stopped answering keepalives and the session ended. Reconnect to "
                    + "start a new one.",
                recoveryLabel: "Reconnect"
            )
        case .cancelledBySwitch:
            ErrorStateCopy(
                title: "Request cancelled",
                body: "Switching sessions cancelled this request. Nothing on the host changed.",
                recoveryLabel: "Try Again"
            )
        }
    }

    public var owningPhase: Int {
        switch self {
        case .connectionRefused, .hostUnreachable, .dnsFallback, .tailscaleSSH, .keepaliveTimeout: 9
        case .cancelledBySwitch: 13
        }
    }
}
