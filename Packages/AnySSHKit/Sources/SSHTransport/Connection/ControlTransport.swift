import AnySSHCore
import Foundation

public actor ControlTransport {
    public nonisolated let kind = TransportKind.ssh
    public nonisolated let capabilities = TransportCapabilities.ssh
    public nonisolated let ledger: ControlChannelLedger

    public private(set) var state: TransportState = .idle

    let target: SessionTarget
    let username: String
    let configuration: SSHSessionConfiguration
    var session: SSHSession?

    init(
        target: SessionTarget,
        username: String,
        configuration: SSHSessionConfiguration,
        ledger: ControlChannelLedger
    ) {
        self.target = target
        self.username = username
        self.configuration = configuration
        self.ledger = ledger
    }

    public var isConnected: Bool {
        state == .connected && session != nil
    }

    func connect(
        credential: AuthCredential,
        trust: HostKeyTrust,
        answering: AuthPromptAnswering?,
        roundTimeout: Duration
    ) async throws {
        guard session == nil else { return }
        let session = SSHSession(target: target, configuration: configuration, trust: trust)
        self.session = session
        state = .connecting
        do {
            try await session.open()
            state = .authenticating
            try await session.authenticate(
                as: username,
                with: credential,
                answering: answering,
                roundTimeout: roundTimeout
            )
            state = .connected
        } catch {
            await close(reason: .failed(stateID: Self.stateID(of: error)))
            throw error
        }
    }

    func run(_ batch: RemoteBatch, limits: BatchLimits = .default) async throws -> BatchResponse {
        let rendered = BatchScriptBuilder().render(batch)
        let bytes = try await execute(rendered.command, limits: limits)
        return try BatchResponseParser(nonce: rendered.nonce, batch: batch, limits: limits)
            .parse(bytes)
    }

    func execute(_ command: String, limits: BatchLimits = .default) async throws -> Data {
        guard let session, state == .connected else { throw TransportFailure.notConnected }
        return try await session.runExec(command, limits: limits, ledger: ledger)
    }

    func uploadFile(_ file: URL, command: String) async throws {
        guard let session, state == .connected else { throw TransportFailure.notConnected }
        try await session.uploadFile(file, command: command, ledger: ledger)
    }

    func close(reason: DisconnectReason) async {
        if let session {
            await session.close(reason: reason)
        }
        session = nil
        state = .disconnected(reason)
    }

    public var identity: SessionIdentity? {
        get async {
            guard let session else { return nil }
            return await session.identity
        }
    }

    private static func stateID(of error: any Error) -> String {
        (error as? any UserFacingError)?.stateID ?? "transport.connectionLost"
    }
}
