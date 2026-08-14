import AnySSHCore
import AnySSHMocks
import Foundation
import Sessions
import TerminalEmulator
import Testing

@testable import AnySSHUI

@Suite @MainActor struct SessionSwitchScrollbackTests {
    @Test func switchingAwayLeavesTheOutgoingScrollbackUnchanged() async throws {
        let model = Self.model()
        let surfaceA = try #require(model.surface(for: Self.idA))

        let pump = surfaceA.pump
        let flood = Task.detached {
            for line in 0..<4_000 {
                await pump.ingest(ArraySlice("flood \(line)\r\n".utf8))
                if line.isMultiple(of: 32) { await Task.yield() }
            }
        }

        #expect(await Self.settledSynchronously { Self.lineCount(of: surfaceA) >= 500 })
        let scopeA = try #require(model.scope(for: Self.idA))

        model.beginSwitch(to: Self.idB)
        await model.completeSwitch()
        #expect(model.activeSessionID == Self.idB)
        #expect(surfaceA.isDraining == false)
        await flood.value

        let linesWhileAway = Self.lineCount(of: surfaceA)
        await surfaceA.pump.ingest(ArraySlice("held while away\r\n".utf8))
        #expect(
            await surfaceA.pump.pendingByteCount > 0,
            "the pause must hold what arrives rather than drop it"
        )
        #expect(
            Self.lineCount(of: surfaceA) == linesWhileAway,
            "the paused drain must not deliver while the session is away"
        )

        model.beginSwitch(to: Self.idA)
        await model.completeSwitch()
        #expect(model.activeSessionID == Self.idA)
        #expect(model.surface(for: Self.idA) === surfaceA)

        #expect(
            await Self.drained(surfaceA),
            "the resumed drain must deliver the backlog, or the pause would be a leak"
        )
        #expect(Self.lineCount(of: surfaceA) > linesWhileAway)
        #expect(surfaceA.isDraining)
        #expect(await scopeA.cancellations == 1)
    }

    private static let idA = SessionID(rawValue: "session-a")
    private static let idB = SessionID(rawValue: "session-b")

    private static func model() -> SessionWorkspaceModel {
        let registry = SessionRegistry([
            record("session-a", connection: "a"), record("session-b", connection: "b"),
        ])
        let connections: [SessionID: any RemoteConnection] = [
            idA: MockRemoteConnection(connectionID: ConnectionID(rawValue: "a")),
            idB: MockRemoteConnection(connectionID: ConnectionID(rawValue: "b")),
        ]
        return SessionWorkspaceModel(
            registry: registry,
            remotes: [],
            activeSessionID: idA,
            connections: connections,
            makeEngine: { size in SwiftTermEngine(size: size, renderer: .coreText) }
        )
    }

    private static func record(_ id: String, connection: String) -> SessionRecord {
        SessionRecord(
            id: SessionID(rawValue: id),
            remoteID: RemoteID(rawValue: "remote"),
            connectionID: ConnectionID(rawValue: connection),
            title: "session \(id)",
            state: .connected,
            capabilities: SessionScenario.ssh,
            createdAt: SessionScenario.epoch,
            lastActiveAt: SessionScenario.epoch
        )
    }

    private static func lineCount(of surface: TerminalSurface) -> Int {
        surface.engine.describeScreen().filter { $0 == "\n" }.count
    }

    private static func drained(_ surface: TerminalSurface) async -> Bool {
        await settled { await surface.pump.pendingByteCount == 0 }
    }

    private static func settledSynchronously(_ condition: () -> Bool) async -> Bool {
        await settled { () async -> Bool in condition() }
    }

    private static func settled(_ condition: () async -> Bool) async -> Bool {
        let deadline = ContinuousClock.now + .seconds(5)
        while ContinuousClock.now < deadline {
            if await condition() { return true }
            await Task.yield()
        }
        return false
    }
}
