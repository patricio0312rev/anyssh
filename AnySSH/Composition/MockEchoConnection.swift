import AnySSHCore
import AnySSHMocks
import Foundation

actor MockEchoConnection: RemoteConnection {
    static let clientPort = 52_000
    static let foregroundProbe = "P claude\nS \(GitFixtures.root)\n"

    nonisolated let connectionID: ConnectionID
    private let inner: MockRemoteConnection
    private var sink: (any ByteSink)?

    init(connectionID: ConnectionID) {
        self.init(
            connectionID: connectionID,
            inner: MockRemoteConnection(
                script: MockControlScript(
                    sections: ["foreground": Data(Self.foregroundProbe.utf8)]
                )
            )
        )
    }

    init(connectionID: ConnectionID, inner: MockRemoteConnection) {
        self.connectionID = connectionID
        self.inner = inner
    }

    private(set) var displayState = TransportState.idle
    private(set) var controlState = TransportState.idle
    let openChannelCount = 0
    let clientPort: Int? = MockEchoConnection.clientPort

    func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        try await inner.run(batch)
    }

    func cancelAll(reason: DisconnectReason) async {
        await inner.cancelAll(reason: reason)
    }

    func close(reason: DisconnectReason) async {
        displayState = .disconnected(reason)
        controlState = .disconnected(reason)
        await inner.close(reason: reason)
    }

    func attachDisplay(sink: any ByteSink, size: TerminalSize) async throws {
        self.sink = sink
        try await inner.attachDisplay(sink: sink, size: size)
        displayState = .connected
        controlState = .connected
    }

    func setDisplayDelegate(_ delegate: any TerminalTransportDelegate) async {
        await inner.setDisplayDelegate(delegate)
    }

    func sendDisplay(_ bytes: ArraySlice<UInt8>) async throws {
        try await inner.sendDisplay(bytes)
        await sink?.ingest(bytes)
    }

    func resizeDisplay(to size: TerminalSize) async throws {
        try await inner.resizeDisplay(to: size)
    }

    func send(_ bytes: ArraySlice<UInt8>) async throws {
        try await sendDisplay(bytes)
    }
}
