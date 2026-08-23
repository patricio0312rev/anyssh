import AnySSHCore
import AnySSHMocks
import Sessions

@testable import AnySSHUI

@MainActor
enum SessionWorkspaceFixture {
    static func model(_ fixture: String = "four") -> SessionWorkspaceModel {
        let records = SessionScenario.records(fixture)
        var connections = [SessionID: any RemoteConnection]()
        for record in records {
            connections[record.id] = MockRemoteConnection(connectionID: record.connectionID)
        }
        return SessionWorkspaceModel(
            registry: SessionRegistry(records),
            remotes: RemoteFixtures.scenario("mixed"),
            activeSessionID: records.first?.id,
            connections: connections,
            makeEngine: { size in SwiftTermEngine(size: size, renderer: .coreText) }
        )
    }

    static func attachedConnection(running process: String) -> MockRemoteConnection {
        MockRemoteConnection(
            connectionID: ConnectionID(rawValue: "attached"),
            script: .foreground(process: process),
            clientPort: attachedClientPort
        )
    }

    private static let attachedClientPort = 51234
}
