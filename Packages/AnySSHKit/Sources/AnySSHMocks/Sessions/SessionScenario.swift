import AnySSHCore
import Foundation

public enum SessionScenario {
    public static let epoch = Date(timeIntervalSince1970: 1_770_000_000)

    public static let ssh = TransportCapabilities(
        roaming: false,
        serverSideResume: false,
        execChannels: true,
        portForwarding: true
    )

    public static let multiplexed = TransportCapabilities(
        roaming: false,
        serverSideResume: true,
        execChannels: true,
        portForwarding: true
    )

    public static func records(_ name: String = "four") -> [SessionRecord] {
        switch name {
        case "empty": []
        case "single": [four[0]]
        case "notifyForeground", "notifyBackground": [notify]
        default: four
        }
    }

    public static let four = [
        record(
            id: "session-1",
            remote: RemoteFixtures.workstation.id,
            connection: "workstation.1",
            title: "dev@workstation: ~/Sites/anyssh",
            state: .connected,
            capabilities: ssh,
            age: 1_800,
            idle: 4,
            workspace: WorkspaceLocation(path: "~/Sites/anyssh", provenance: .shellIntegration)
        ),
        record(
            id: "session-2",
            remote: RemoteFixtures.buildBox.id,
            connection: "build-box.1",
            title: "ci@build-box: tmux ci",
            state: .connected,
            capabilities: multiplexed,
            age: 900,
            idle: 61,
            workspace: WorkspaceLocation(path: "/srv/ci/anyssh", provenance: .multiplexer)
        ),
        record(
            id: "session-3",
            remote: RemoteFixtures.edgeNode.id,
            connection: "edge-node.1",
            title: "root@edge-node",
            state: .reconnecting(attempt: 2),
            capabilities: ssh,
            age: 420,
            idle: 118
        ),
        record(
            id: "session-4",
            remote: RemoteFixtures.workstation.id,
            connection: "workstation.2",
            title: "dev@workstation: ~/tmp",
            state: .disconnected(.closedByRemote),
            capabilities: ssh,
            age: 240,
            idle: 200
        ),
    ]

    public static let notify = record(
        id: "notify-1",
        remote: RemoteFixtures.workstation.id,
        connection: "notify.1",
        title: "dev@workstation: backup",
        state: .connected,
        capabilities: ssh,
        age: 120,
        idle: 5
    )

    private static func record(
        id: String,
        remote: RemoteID,
        connection: String,
        title: String,
        state: TransportState,
        capabilities: TransportCapabilities,
        age: TimeInterval,
        idle: TimeInterval,
        workspace: WorkspaceLocation? = nil
    ) -> SessionRecord {
        SessionRecord(
            id: SessionID(rawValue: id),
            remoteID: remote,
            connectionID: ConnectionID(rawValue: connection),
            title: title,
            state: state,
            capabilities: capabilities,
            reconnectAttempts: attempts(for: state),
            createdAt: epoch.addingTimeInterval(-age),
            lastActiveAt: epoch.addingTimeInterval(-idle),
            workspace: workspace
        )
    }

    private static func attempts(for state: TransportState) -> Int {
        guard case .reconnecting(let attempt) = state else { return 0 }
        return attempt
    }
}
