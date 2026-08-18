import AnySSHCore
import AnySSHMocks
import Foundation
import Sessions
import Testing

@testable import AnySSHUI

@Suite @MainActor struct ReconnectMultiplexerTests {
    @Test func reconnectReplacesTheStaleMultiplexerAdapter() async throws {
        let remote = Remote(
            id: RemoteID(rawValue: "r1"),
            name: "box",
            host: "100.1.2.3",
            port: 22,
            username: "dev",
            authMethod: .password
        )
        let sessionID = SessionID(rawValue: "s1")
        let first = MockRemoteConnection(connectionID: ConnectionID(rawValue: "c1"))
        let second = MockRemoteConnection(
            connectionID: ConnectionID(rawValue: "c2"),
            script: MockControlScript(sections: ["capabilities": Data(Self.herdr.utf8)])
        )
        var dial = 0
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
            makeConnection: { _, _ in
                dial += 1
                return dial == 1
                    ? second
                    : MockRemoteConnection(connectionID: ConnectionID(rawValue: "c\(dial)"))
            }
        )
        model.replaceMultiplexer(
            for: sessionID,
            with: FixtureMultiplexerAdapter(fixture: .tmuxMain)
        )
        #expect(model.activeMultiplexerAdapter?.kind == .tmux)

        await model.reconnect(sessionID, forced: true)

        #expect(model.registry[sessionID]?.state == .connected)
        #expect(model.activeMultiplexerAdapter?.kind == .herdr)
        #expect(model.navbarTitle(mode: .multiplexer) == "herdr")
    }

    private static let herdr = """
        anyssh-capabilities/1
        shell\t/bin/zsh
        platform\tDarwin arm64
        locale\ten_US.UTF-8
        home\t/Users/dev
        path\t/Users/dev/.local/bin:/opt/homebrew/bin:/usr/bin
        git.path\t/opt/homebrew/bin/git
        git.version\tgit version 2.54.0
        tmux.path\t/opt/homebrew/bin/tmux
        tmux.version\ttmux 3.6a
        herdr.path\t/Users/dev/.local/bin/herdr
        herdr.version\therdr 0.8.0
        herdr.protocol\t\(HerdrReport.supportedProtocolVersion)

        """
}
