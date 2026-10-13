import AnySSHCore
import AnySSHMocks
import Foundation
import Sessions
import TerminalEmulator
import Testing

@testable import AnySSHUI

@Suite @MainActor struct FreshShellResetTests {
    private static let oldProgramModes = Array(
        "\u{1B}[?1049h\u{1B}[?1h\u{1B}[?1002h\u{1B}[?1006h\u{1B}[?2004hTUI".utf8
    )
    private static let allOn = TerminalModeSnapshot(
        applicationCursor: true,
        alternateBuffer: true,
        mouseReporting: true
    )
    private static let allOff = TerminalModeSnapshot(
        applicationCursor: false,
        alternateBuffer: false,
        mouseReporting: false
    )

    @Test func theResetTurnsOffWhatTheOldProgramLeftOnAndKeepsTheText() {
        let engine = SwiftTermEngine(size: .standard, renderer: .coreText)
        engine.feed(ArraySlice(Array("$ echo kept\r\nkept\r\n$ ".utf8)))
        engine.feed(ArraySlice(Self.oldProgramModes))
        #expect(engine.modes == Self.allOn)
        #expect(engine.pastesBracketed)

        engine.feed(ArraySlice(TerminalModeReset.bytes))

        #expect(engine.modes == Self.allOff)
        #expect(!engine.pastesBracketed)
        #expect(engine.describeScreen().contains("echo kept"))
    }

    @Test func aReconnectResetsTheTerminalBeforeTheNewShellSpeaks() async throws {
        let sessionID = SessionID(rawValue: "s1")
        let remote = Remote(id: RemoteID(rawValue: "r1"), name: "box", host: "100.1.2.3", username: "dev")
        let first = MockRemoteConnection(connectionID: ConnectionID(rawValue: "c1"))
        let model = SessionWorkspaceModel(
            registry: SessionRegistry([
                SessionRecord(
                    id: sessionID,
                    remoteID: remote.id,
                    connectionID: first.connectionID,
                    title: remote.name,
                    state: .disconnected(.backgrounded),
                    capabilities: .ssh,
                    reconnectAttempts: 0,
                    createdAt: Date(timeIntervalSince1970: 0),
                    lastActiveAt: Date(timeIntervalSince1970: 0)
                )
            ]),
            remotes: [remote],
            activeSessionID: sessionID,
            connections: [sessionID: first],
            makeEngine: { size in SwiftTermEngine(size: size, renderer: .coreText) },
            makeConnection: { _, _ in MockRemoteConnection(connectionID: ConnectionID(rawValue: "c2")) },
            isWorkspacePresented: { true }
        )
        let surface = try #require(model.store.surface(for: sessionID))
        let engine = try #require(surface.engine as? SwiftTermEngine)
        await surface.pump.ingest(ArraySlice(Self.oldProgramModes))
        try await Self.settle { engine.modes == Self.allOn }

        await model.reconnect(sessionID, forced: true)

        try await Self.settle { engine.modes == Self.allOff }
        #expect(!engine.pastesBracketed)
        #expect(engine.describeScreen().contains("-- reconnected "))
    }

    private static func settle(_ condition: () -> Bool) async throws {
        for _ in 0..<200 where !condition() {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(condition())
    }
}
