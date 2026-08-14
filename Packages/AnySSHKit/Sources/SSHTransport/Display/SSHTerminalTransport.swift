import AnySSHCore
import Foundation

public actor SSHTerminalTransport: TerminalTransport {
    public nonisolated let kind = TransportKind.ssh
    public nonisolated let capabilities = TransportCapabilities.ssh

    public private(set) var state: TransportState = .idle
    public internal(set) var size = TerminalSize.standard

    let target: SessionTarget
    let username: String
    let credential: AuthCredential
    let hostKeys: any HostKeyStore
    let configuration: DisplayTransportConfiguration

    var delegate: (any TerminalTransportDelegate)?
    var sink: (any ByteSink)?
    var session: SSHSession?

    public var clientPort: Int? {
        get async { await session?.identity?.localPort }
    }
    var channel: SSHChannel?
    var reader: Task<Void, Never>?

    public init(
        target: SessionTarget,
        username: String,
        credential: AuthCredential,
        hostKeys: any HostKeyStore,
        configuration: DisplayTransportConfiguration = .init()
    ) {
        self.target = target
        self.username = username
        self.credential = credential
        self.hostKeys = hostKeys
        self.configuration = configuration
    }

    public func setDelegate(_ delegate: any TerminalTransportDelegate) {
        self.delegate = delegate
    }

    public func setSink(_ sink: any ByteSink) {
        self.sink = sink
    }

    public func send(_ bytes: ArraySlice<UInt8>) async throws {
        guard let session, let channel else { throw TransportFailure.notConnected }
        try await session.writeShell(channel, bytes)
    }

    public func resize(to size: TerminalSize) async throws {
        guard let session, let channel else {
            self.size = size
            return
        }
        try await session.resizePTY(channel, to: size)
        self.size = size
    }

    public func close() async {
        await teardown(reason: .closedByUser)
    }

    public var isReading: Bool {
        reader?.isCancelled == false
    }

    func teardown(reason: DisconnectReason) async {
        guard !isDisconnected else { return }
        reader?.cancel()
        reader = nil
        channel = nil
        if let session {
            await session.close(reason: reason)
        }
        session = nil
        await transition(to: .disconnected(reason))
    }

    func transition(to next: TransportState) async {
        guard state != next else { return }
        state = next
        guard let delegate else { return }
        await delegate.transport(self, didChange: next)
    }

    private var isDisconnected: Bool {
        guard case .disconnected = state else { return false }
        return true
    }
}
