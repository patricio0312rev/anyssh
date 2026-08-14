import AnySSHCore
import AnySSHMocks
import Testing

@testable import AnySSHUI

@Suite struct SurfaceStoreLifecycleTests {
    @Test func reopeningASessionHandsBackTheSurfaceItAlreadyHas() {
        let store = Self.store()
        let id = SessionID(rawValue: "session-1")
        let connection = Self.connection("workstation.1")

        let first = store.open(id, on: connection)
        let second = store.open(id, on: connection)

        #expect(first === second)
        #expect(store.count == 1)
        #expect(store.sessionIDs == [id])
    }

    @Test func reopeningAfterAReconnectRebindsTheSurfaceToTheNewConnection() async {
        let store = Self.store()
        let id = SessionID(rawValue: "session-1")
        let dialled = Self.connection("workstation.1")
        let redialled = Self.connection("workstation.2")

        let surface = store.open(id, on: dialled)
        let rebound = store.open(id, on: redialled)

        #expect(surface === rebound)
        #expect(surface.connectionID.rawValue == "workstation.2")
        await store.close(id)
        #expect(await redialled.displayState == .disconnected(.closedByUser))
        #expect(await dialled.displayState == .idle)
    }

    @Test func everySessionGetsItsOwnSurfaceAndItsOwnView() {
        let store = Self.store()
        let first = store.open(SessionID(rawValue: "a"), on: Self.connection("a"))
        let second = store.open(SessionID(rawValue: "b"), on: Self.connection("b"))

        #expect(first !== second)
        #expect(first.engine !== second.engine)
        #expect(first.view !== second.view)
        #expect(store.count == 2)
    }

    @Test func closingEndsTheDrainAndTheConnectionBehindIt() async {
        let store = Self.store()
        let id = SessionID(rawValue: "session-1")
        let connection = Self.connection("workstation.1")
        let surface = store.open(id, on: connection)

        #expect(surface.isDraining)
        await store.close(id)

        #expect(store.surface(for: id) == nil)
        #expect(store.count == 0)
        #expect(!surface.isDraining)
        #expect(await connection.displayState == .disconnected(.closedByUser))
    }

    @Test func closingASessionThatIsNotOpenDoesNothing() async {
        let store = Self.store()

        await store.close(SessionID(rawValue: "missing"))

        #expect(store.count == 0)
    }

    @Test func closeAllEndsEverySession() async {
        let store = Self.store()
        let connections = ["a", "b", "c"].map { Self.connection($0) }
        for (index, connection) in connections.enumerated() {
            store.open(SessionID(rawValue: "session-\(index)"), on: connection)
        }

        await store.closeAll(reason: .closedByUser)

        #expect(store.count == 0)
        for connection in connections {
            #expect(await connection.displayState == .disconnected(.closedByUser))
        }
    }

    private static func store() -> TerminalSurfaceStore {
        TerminalSurfaceStore { size in SwiftTermEngine(size: size, renderer: .coreText) }
    }

    private static func connection(_ id: String) -> MockRemoteConnection {
        MockRemoteConnection(connectionID: ConnectionID(rawValue: id))
    }
}
