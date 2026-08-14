import AnySSHCore
import AnySSHMocks
import Foundation
import Sessions
import Testing

@testable import AnySSHUI

@Suite @MainActor struct ReconnectStartupOnceTests {
    @Test func workspaceReconnectSendsStartupCommandOnce() async throws {
        let remote = Remote(
            id: RemoteID(rawValue: "r1"),
            name: "box",
            host: "100.1.2.3",
            port: 22,
            username: "patricio",
            authMethod: .password,
            startupCommand: "printf 'ANYSSH-START\\n'"
        )
        let sessionID = SessionID(rawValue: "s1")
        let first = MockRemoteConnection(connectionID: ConnectionID(rawValue: "c1"))
        await first.setDisplayState(.disconnected(.backgrounded))
        let second = MockRemoteConnection(connectionID: ConnectionID(rawValue: "c2"))
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

        await model.reconnect(sessionID, forced: true)

        let writes = await second.displayWrites
        let expected = Array("printf 'ANYSSH-START\\n'\n".utf8)
        #expect(writes == [expected])
        #expect(await second.attachCount == 1)
        #expect(model.registry[sessionID]?.state == .connected)
        #expect(model.registry[sessionID]?.reconnectAttempts == 0)
    }
}
