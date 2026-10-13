import AnySSHCore
import AnySSHMocks
import Foundation
import Sessions
import Testing

@testable import AnySSHUI

@Suite @MainActor struct ReconnectReattachTests {
    private static let sessionID = SessionID(rawValue: "s1")
    private static let freshShell = "P sshd-session\nP zsh\n"

    @Test func aSessionThatWasInsideTmuxLandsBackInItsSession() async throws {
        let redial = Self.redial(foreground: Self.freshShell)
        let model = Self.model(redial: redial)
        model.noteForeground(["zsh", "tmux"], for: Self.sessionID)

        await model.reconnect(Self.sessionID, forced: true)

        #expect(model.registry[Self.sessionID]?.state == .connected)
        #expect(await redial.displayWrites.contains(Self.attachBytes))
        #expect(model.sessionsInsideMux.contains(Self.sessionID))
    }

    @Test func aSessionLastSeenInAPlainShellStaysInTheNewShell() async throws {
        let redial = Self.redial(foreground: Self.freshShell)
        let model = Self.model(redial: redial)
        model.noteForeground(["zsh", "tmux"], for: Self.sessionID)
        model.noteForeground(["zsh"], for: Self.sessionID)

        await model.reconnect(Self.sessionID, forced: true)

        #expect(model.registry[Self.sessionID]?.state == .connected)
        #expect(await !redial.displayWrites.contains(Self.attachBytes))
    }

    @Test func anUnknownForegroundProgramNeverReceivesTheAttachCommand() async throws {
        let redial = Self.redial(foreground: Self.freshShell + "P gitstatusd\n")
        let model = Self.model(redial: redial)
        model.noteForeground(["zsh", "tmux"], for: Self.sessionID)

        await model.reconnect(Self.sessionID, forced: true)

        #expect(model.registry[Self.sessionID]?.state == .connected)
        #expect(await redial.displayWrites.isEmpty)
    }

    @Test func aStartupCommandKeepsTheReconnectFromTypingAnAttach() async throws {
        let redial = Self.redial(foreground: Self.freshShell)
        let model = Self.model(redial: redial, startupCommand: "herdr")
        model.noteForeground(["zsh", "tmux"], for: Self.sessionID)

        await model.reconnect(Self.sessionID, forced: true)

        #expect(await redial.displayWrites == [Array("herdr\n".utf8)])
    }

    private static var attachBytes: [UInt8] {
        let target = MuxTarget(session: MuxSessionID(rawValue: "$1"))
        return Array((FixtureMultiplexerAdapter(fixture: .tmuxMain).attachCommand(target) + "\r").utf8)
    }

    private static func redial(foreground: String) -> MockRemoteConnection {
        MockRemoteConnection(
            connectionID: ConnectionID(rawValue: "c2"),
            script: MockControlScript(duration: .zero, sections: ["foreground": Data(foreground.utf8)]),
            clientPort: 51234
        )
    }

    private static func model(
        redial: MockRemoteConnection,
        startupCommand: String? = nil
    ) -> SessionWorkspaceModel {
        let remote = Remote(
            id: RemoteID(rawValue: "r1"),
            name: "box",
            host: "100.1.2.3",
            username: "dev",
            authMethod: .password,
            startupCommand: startupCommand
        )
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
            makeConnection: { _, _ in redial },
            isWorkspacePresented: { true }
        )
        model.replaceMultiplexer(for: sessionID, with: FixtureMultiplexerAdapter(fixture: .tmuxMain))
        return model
    }
}
