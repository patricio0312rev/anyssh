import AnySSHCore
import Foundation
import Testing

@testable import Sessions

@Suite struct StartupCommandSenderTests {
    @Test func theStartupCommandIsSentExactlyOncePerReconnectAttach() async throws {
        let remote = Remote(
            id: RemoteID(rawValue: "r1"),
            name: "box",
            host: "100.1.2.3",
            port: 22,
            username: "dev",
            authMethod: .password,
            startupCommand: "printf 'ANYSSH-START\\n'"
        )
        let connection = RecordingConnection()
        let sender = StartupCommandSender()

        try await sender.send(on: connection, remote: remote)
        try await sender.send(on: connection, remote: remote)

        let writes = await connection.displayWrites
        #expect(writes.count == 2)
        let expected = Array("printf 'ANYSSH-START\\n'\n".utf8)
        #expect(writes[0] == expected)
        #expect(writes[1] == expected)
        #expect(Set(writes.map { $0 }).count == 1)
    }

    @Test func aBlankStartupCommandIsNotSent() async throws {
        let remote = Remote(
            id: RemoteID(rawValue: "r1"),
            name: "box",
            host: "100.1.2.3",
            port: 22,
            username: "dev",
            authMethod: .password,
            startupCommand: "   "
        )
        let connection = RecordingConnection()
        try await StartupCommandSender().send(on: connection, remote: remote)
        #expect(await connection.displayWrites.isEmpty)
    }
}

private actor RecordingConnection: RemoteConnection {
    nonisolated let connectionID = ConnectionID(rawValue: "record")
    var displayState = TransportState.idle
    var controlState = TransportState.idle
    var openChannelCount = 0
    var clientPort: Int? { nil }
    private(set) var displayWrites: [[UInt8]] = []

    func cancelAll(reason: DisconnectReason) async {}
    func close(reason: DisconnectReason) async {
        displayState = .disconnected(reason)
    }
    func attachDisplay(sink: any ByteSink, size: TerminalSize) async throws {
        _ = sink
        _ = size
        displayState = .connected
    }
    func setDisplayDelegate(_ delegate: any TerminalTransportDelegate) async {
        _ = delegate
    }
    func sendDisplay(_ bytes: ArraySlice<UInt8>) async throws {
        displayWrites.append(Array(bytes))
    }
    func send(_ bytes: ArraySlice<UInt8>) async throws {
        try await sendDisplay(bytes)
    }
    func resizeDisplay(to size: TerminalSize) async throws {
        _ = size
    }
    func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        BatchResponse(sections: [])
    }
}
