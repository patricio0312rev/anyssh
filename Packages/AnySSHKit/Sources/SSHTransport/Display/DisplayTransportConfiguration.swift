import AnySSHCore

public struct DisplayTransportConfiguration: Sendable {
    public var term: String
    public var session: SSHSessionConfiguration
    public var roundTimeout: Duration

    public init(
        term: String = "xterm-256color",
        session: SSHSessionConfiguration = .init(),
        roundTimeout: Duration = .seconds(120)
    ) {
        self.term = term
        self.session = session
        self.roundTimeout = roundTimeout
    }
}
