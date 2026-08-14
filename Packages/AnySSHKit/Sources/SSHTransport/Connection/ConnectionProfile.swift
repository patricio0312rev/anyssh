import AnySSHCore

public struct ConnectionProfile: Sendable {
    public static let defaultControlIdleTTL = Duration.seconds(120)

    public let connectionID: ConnectionID
    public let target: SessionTarget
    public let username: String
    public let display: DisplayTransportConfiguration
    public let control: SSHSessionConfiguration
    public let controlIdleTTL: Duration

    public init(
        connectionID: ConnectionID,
        target: SessionTarget,
        username: String,
        display: DisplayTransportConfiguration = .init(),
        control: SSHSessionConfiguration = .init(),
        controlIdleTTL: Duration = ConnectionProfile.defaultControlIdleTTL
    ) {
        self.connectionID = connectionID
        self.target = target
        self.username = username
        self.display = display
        self.control = control
        self.controlIdleTTL = controlIdleTTL
    }
}

public enum ConnectionSide: String, Hashable, Sendable, CaseIterable {
    case display
    case control
}

public enum ConnectionPrompting {
    public static func note(
        for credential: AuthCredential,
        dialling side: ConnectionSide,
        isFirstTransport: Bool
    ) -> TransportNote? {
        guard case .keyboardInteractive = credential, !isFirstTransport else { return nil }
        return .secondPromptRequired(transport: side.rawValue)
    }
}
