import AnySSHCore

public enum ReconnectSurvivalCopy: Sendable {
    public static func state(for capabilities: TransportCapabilities) -> ErrorState {
        if capabilities.roaming {
            return .session(.survivalRoaming)
        }
        if capabilities.serverSideResume {
            return .session(.survivalMultiplexed)
        }
        return .session(.survivalSSH)
    }

    public static func body(for capabilities: TransportCapabilities) -> String {
        state(for: capabilities).copy.body
    }

    public static func title(for capabilities: TransportCapabilities) -> String {
        state(for: capabilities).copy.title
    }

    public static func recoveryLabel(for capabilities: TransportCapabilities) -> String {
        state(for: capabilities).copy.recoveryLabel
    }
}
