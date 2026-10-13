import AnySSHCore
import AnySSHMocks
import Foundation
import Sessions
import Testing

@testable import AnySSHUI

@Suite @MainActor struct SessionCloseTeardownTests {
    @Test func closingUnregistersTheSessionBeforeTheConnectionFinishesClosing() async throws {
        let fixture = await CloseTeardownFixture.make()
        let model = fixture.model
        let alphaID = try #require(fixture.session(on: CloseTeardownFixture.alpha.id))

        let closing = Task { await model.close(alphaID) }
        try await waitUntil { await fixture.hanging.isClosing }

        #expect(model.registry[alphaID] == nil)
        #expect(await fixture.hanging.didFinishClose == false)

        await fixture.hanging.release()
        await closing.value
        #expect(model.registry[alphaID] == nil)
    }

    @Test func aHungCloseLeavesNoReconnectCandidate() async throws {
        let fixture = await CloseTeardownFixture.make()
        let model = fixture.model
        let alphaID = try #require(fixture.session(on: CloseTeardownFixture.alpha.id))
        let bravoID = try #require(fixture.session(on: CloseTeardownFixture.bravo.id))
        model.startReconnectMonitoring()
        let closing = Task { await model.close(alphaID) }
        try await waitUntil { await fixture.hanging.isClosing }
        model.surface(for: bravoID)?.startDraining()
        model.markBackgroundedSessions()
        let alphaDials = fixture.dials.count(for: CloseTeardownFixture.alpha.id)

        await model.reconnectCoordinator.requestReconnects(for: .foreground)

        #expect(model.reconnectCoordinator.lastTriggeredSessionIDs == [bravoID])
        #expect(fixture.dials.count(for: CloseTeardownFixture.alpha.id) == alphaDials)
        #expect(model.registry[alphaID] == nil)

        await fixture.hanging.release()
        await closing.value
    }

    @Test func closingTheActiveSessionPromotesTheNextOneBeforeTheSocketCloses() async throws {
        let fixture = await CloseTeardownFixture.make()
        let model = fixture.model
        let alphaID = try #require(fixture.session(on: CloseTeardownFixture.alpha.id))
        let bravoID = try #require(fixture.session(on: CloseTeardownFixture.bravo.id))
        #expect(model.activeSessionID == alphaID)

        let closing = Task { await model.close(alphaID) }
        try await waitUntil { await fixture.hanging.isClosing }

        #expect(model.activeSessionID == bravoID)

        await fixture.hanging.release()
        await closing.value
        #expect(model.activeSessionID == bravoID)
    }

    @Test func closingTheLastSessionEmptiesTheRegistryWhileTheSocketStillHangs() async throws {
        let fixture = await CloseTeardownFixture.make()
        let model = fixture.model
        let alphaID = try #require(fixture.session(on: CloseTeardownFixture.alpha.id))
        let bravoID = try #require(fixture.session(on: CloseTeardownFixture.bravo.id))
        await model.close(bravoID)

        let closing = Task { await model.close(alphaID) }
        try await waitUntil { await fixture.hanging.isClosing }

        #expect(model.registry.isEmpty)
        #expect(model.scope(for: alphaID) == nil)
        #expect(model.connection(for: alphaID) == nil)

        await fixture.hanging.release()
        await closing.value
    }
}

@MainActor
private struct CloseTeardownFixture {
    static let alpha = Remote(
        id: RemoteID(rawValue: "alpha"),
        name: "alpha",
        host: "10.0.0.1",
        username: "dev",
        authMethod: .publicKey
    )
    static let bravo = Remote(
        id: RemoteID(rawValue: "bravo"),
        name: "bravo",
        host: "10.0.0.2",
        username: "dev",
        authMethod: .password
    )

    let model: SessionWorkspaceModel
    let dials: RemoteDialLog
    let hanging: HangingCloseConnection

    static func make() async -> CloseTeardownFixture {
        let dials = RemoteDialLog()
        let hanging = HangingCloseConnection(
            connectionID: ConnectionID(rawValue: "alpha.hanging")
        )
        let model = SessionWorkspaceModel(
            registry: SessionRegistry(),
            remotes: [alpha, bravo],
            activeSessionID: nil,
            connections: [:],
            makeEngine: { size in SwiftTermEngine(size: size, renderer: .coreText) },
            makeConnection: { remote, _ in
                dials.record(remote.id)
                guard remote.id != alpha.id else { return hanging }
                return MockRemoteConnection(
                    connectionID: ConnectionID(
                        rawValue: "\(remote.id.rawValue).\(dials.count(for: remote.id))"
                    )
                )
            },
            reconnectCoordinator: ReconnectCoordinator(pathSignal: ScriptedPathSignal()),
            isWorkspacePresented: { true }
        )
        await model.open(remote: bravo)
        await model.open(remote: alpha)
        return CloseTeardownFixture(model: model, dials: dials, hanging: hanging)
    }

    func session(on remoteID: RemoteID) -> SessionID? {
        model.registry.sessions.first { $0.remoteID == remoteID }?.id
    }
}

@MainActor
private final class RemoteDialLog {
    private var remoteIDs: [RemoteID] = []

    func record(_ id: RemoteID) {
        remoteIDs.append(id)
    }

    func count(for id: RemoteID) -> Int {
        remoteIDs.filter { $0 == id }.count
    }
}

private actor HangingCloseConnection: RemoteConnection {
    nonisolated let connectionID: ConnectionID

    private(set) var displayState = TransportState.idle
    private(set) var controlState = TransportState.idle
    private(set) var openChannelCount = 0
    private(set) var isClosing = false
    private(set) var didFinishClose = false
    var clientPort: Int? { nil }

    private var continuation: CheckedContinuation<Void, Never>?
    private var isReleased = false

    init(connectionID: ConnectionID) {
        self.connectionID = connectionID
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
        isClosing = true
        if !isReleased {
            await withCheckedContinuation { self.continuation = $0 }
        }
        displayState = .disconnected(reason)
        controlState = .disconnected(reason)
        didFinishClose = true
    }

    func release() {
        isReleased = true
        continuation?.resume()
        continuation = nil
    }
}
