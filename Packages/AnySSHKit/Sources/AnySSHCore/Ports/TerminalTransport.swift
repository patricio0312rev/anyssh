public protocol TerminalTransport: Actor {
    nonisolated var kind: TransportKind { get }
    nonisolated var capabilities: TransportCapabilities { get }
    var state: TransportState { get }

    func setDelegate(_ delegate: any TerminalTransportDelegate)
    func setSink(_ sink: any ByteSink)
    func start(size: TerminalSize) async throws
    func send(_ bytes: ArraySlice<UInt8>) async throws
    func resize(to size: TerminalSize) async throws
    func close() async
}

public protocol TerminalTransportDelegate: Sendable {
    func transport(
        _ transport: any TerminalTransport,
        verify key: HostKey,
        status: KnownHostStatus
    ) async -> HostKeyVerdict

    func transport(
        _ transport: any TerminalTransport,
        answer round: AuthPromptRound
    ) async -> AuthPromptAnswer

    func transport(_ transport: any TerminalTransport, didChange state: TransportState) async
}
