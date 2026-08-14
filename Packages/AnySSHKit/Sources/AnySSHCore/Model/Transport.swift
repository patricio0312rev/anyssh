public enum TransportKind: String, CaseIterable, Sendable {
    case ssh
    case mosh
    case eternalTerminal
}

public struct TransportCapabilities: Hashable, Sendable {
    public let roaming: Bool
    public let serverSideResume: Bool
    public let execChannels: Bool
    public let portForwarding: Bool

    public init(
        roaming: Bool,
        serverSideResume: Bool,
        execChannels: Bool,
        portForwarding: Bool
    ) {
        self.roaming = roaming
        self.serverSideResume = serverSideResume
        self.execChannels = execChannels
        self.portForwarding = portForwarding
    }

    public static let ssh = TransportCapabilities(
        roaming: false,
        serverSideResume: false,
        execChannels: true,
        portForwarding: true
    )
}

public enum DisconnectReason: Hashable, Sendable {
    case closedByUser
    case closedByRemote
    case backgrounded
    case cancelledBySwitch
    case failed(stateID: String)
}

public enum TransportState: Hashable, Sendable {
    case idle
    case connecting
    case authenticating
    case connected
    case reconnecting(attempt: Int)
    case disconnected(DisconnectReason)
}
