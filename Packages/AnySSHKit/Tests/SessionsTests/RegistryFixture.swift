import AnySSHCore
import Foundation

enum RegistryFixture {
    static let epoch = Date(timeIntervalSince1970: 1_770_000_000)

    static let ssh = TransportCapabilities(
        roaming: false,
        serverSideResume: false,
        execChannels: true,
        portForwarding: true
    )

    static let multiplexed = TransportCapabilities(
        roaming: false,
        serverSideResume: true,
        execChannels: true,
        portForwarding: true
    )

    static func record(
        _ id: String,
        remote: String = "workstation",
        connection: String? = nil,
        title: String = "workstation",
        state: TransportState = .connecting,
        capabilities: TransportCapabilities = ssh,
        idle: TimeInterval = 0
    ) -> SessionRecord {
        SessionRecord(
            id: SessionID(rawValue: id),
            remoteID: RemoteID(rawValue: remote),
            connectionID: ConnectionID(rawValue: connection ?? "\(remote).\(id)"),
            title: title,
            state: state,
            capabilities: capabilities,
            createdAt: epoch,
            lastActiveAt: epoch.addingTimeInterval(-idle)
        )
    }

    static func id(_ value: String) -> SessionID {
        SessionID(rawValue: value)
    }
}
