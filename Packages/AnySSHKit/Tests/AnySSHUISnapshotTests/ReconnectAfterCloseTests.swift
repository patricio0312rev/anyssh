import AnySSHCore
import AnySSHMocks
import Foundation
import Sessions
import Testing

@testable import AnySSHUI

@Suite @MainActor struct ReconnectAfterCloseTests {
    @Test func closingWhileTheOldSocketClosesNeverDialsAgain() async throws {
        let first = GatedReconnectConnection(
            connectionID: ConnectionID(rawValue: "alpha.1"),
            gate: .firstClose
        )
        let fixture = await ReconnectAfterCloseFixture.make(handing: [first])
        let model = fixture.model
        let id = try #require(fixture.sessionID)
        model.markBackgroundedSessions()

        let reconnecting = Task { await model.reconnect(id, forced: true) }
        try await waitUntil { await first.isHeld }
        await model.close(id)
        await first.release()
        await reconnecting.value

        #expect(fixture.dials.count == 1)
        #expect(model.registry[id] == nil)
        #expect(model.surface(for: id) == nil)
        #expect(model.connection(for: id) == nil)
        #expect(model.scope(for: id) == nil)
    }

    @Test func closingDuringTheHandshakeDropsTheFreshConnectionQuietly() async throws {
        let fresh = GatedReconnectConnection(
            connectionID: ConnectionID(rawValue: "alpha.2"),
            gate: .attach
        )
        let fixture = await ReconnectAfterCloseFixture.make(
            handing: [MockRemoteConnection(connectionID: ConnectionID(rawValue: "alpha.1")), fresh]
        )
        let model = fixture.model
        let toasts = StatusToastCenter()
        model.statusToasts = toasts
        let id = try #require(fixture.sessionID)
        model.markBackgroundedSessions()

        let reconnecting = Task { await model.reconnect(id, forced: true) }
        try await waitUntil { await fresh.isHeld }
        await model.close(id)
        await fresh.release()
        await reconnecting.value

        #expect(toasts.items.isEmpty)
        #expect(await fresh.closeCount >= 1)
        #expect(model.registry[id] == nil)
        #expect(model.surface(for: id) == nil)
        #expect(model.connection(for: id) == nil)
        #expect(model.scope(for: id) == nil)
    }
}

@MainActor
private struct ReconnectAfterCloseFixture {
    static let alpha = Remote(
        id: RemoteID(rawValue: "alpha"),
        name: "alpha",
        host: "10.0.0.1",
        username: "dev",
        authMethod: .publicKey
    )

    let model: SessionWorkspaceModel
    let dials: HandedConnections

    var sessionID: SessionID? {
        model.registry.sessions.first?.id
    }

    static func make(handing queue: [any RemoteConnection]) async -> ReconnectAfterCloseFixture {
        let dials = HandedConnections(queue)
        let model = SessionWorkspaceModel(
            registry: SessionRegistry(),
            remotes: [alpha],
            activeSessionID: nil,
            connections: [:],
            makeEngine: { size in SwiftTermEngine(size: size, renderer: .coreText) },
            makeConnection: { _, _ in dials.next() },
            reconnectCoordinator: ReconnectCoordinator(pathSignal: ScriptedPathSignal()),
            isWorkspacePresented: { true }
        )
        await model.open(remote: alpha)
        return ReconnectAfterCloseFixture(model: model, dials: dials)
    }
}

@MainActor
private final class HandedConnections {
    private var queue: [any RemoteConnection]
    private(set) var count = 0

    init(_ queue: [any RemoteConnection]) {
        self.queue = queue
    }

    func next() -> any RemoteConnection {
        count += 1
        guard !queue.isEmpty else {
            return MockRemoteConnection(connectionID: ConnectionID(rawValue: "alpha.extra.\(count)"))
        }
        return queue.removeFirst()
    }
}

private actor GatedReconnectConnection: RemoteConnection {
    enum Gate {
        case firstClose
        case attach
    }

    nonisolated let connectionID: ConnectionID
    private let gate: Gate

    private(set) var displayState = TransportState.idle
    private(set) var controlState = TransportState.idle
    private(set) var openChannelCount = 0
    private(set) var isHeld = false
    private(set) var closeCount = 0
    var clientPort: Int? { nil }

    private var isReleased = false
    private var continuation: CheckedContinuation<Void, Never>?

    init(connectionID: ConnectionID, gate: Gate) {
        self.connectionID = connectionID
        self.gate = gate
    }

    func attachDisplay(sink: any ByteSink, size: TerminalSize) async throws {
        _ = sink
        _ = size
        if gate == .attach { await hold() }
        displayState = .connected
    }

    func setDisplayDelegate(_ delegate: any TerminalTransportDelegate) async {
        _ = delegate
    }

    func sendDisplay(_ bytes: ArraySlice<UInt8>) async throws {
        _ = bytes
    }

    func send(_ bytes: ArraySlice<UInt8>) async throws {
        _ = bytes
    }

    func resizeDisplay(to size: TerminalSize) async throws {
        _ = size
    }

    func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        _ = batch
        throw ErrorState.transport(.connectionRefused)
    }

    func cancelAll(reason: DisconnectReason) async {
        _ = reason
    }

    func close(reason: DisconnectReason) async {
        closeCount += 1
        if gate == .firstClose, closeCount == 1 { await hold() }
        displayState = .disconnected(reason)
        controlState = .disconnected(reason)
    }

    func release() {
        isReleased = true
        continuation?.resume()
        continuation = nil
    }

    private func hold() async {
        isHeld = true
        guard !isReleased else { return }
        await withCheckedContinuation { continuation = $0 }
    }
}
