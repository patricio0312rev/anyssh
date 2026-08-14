import AnySSHCore
import Foundation
import Sessions

@MainActor
enum SessionOpenService {
    static func liveSessionIDs(
        on remoteID: RemoteID,
        in registry: SessionRegistry
    ) -> [SessionID] {
        registry.sessions.compactMap { record in
            record.remoteID == remoteID && isLive(record.state) ? record.id : nil
        }
    }

    static func deadSessionIDs(
        on remoteID: RemoteID,
        in registry: SessionRegistry
    ) -> [SessionID] {
        registry.sessions.compactMap { record in
            record.remoteID == remoteID && !isLive(record.state) ? record.id : nil
        }
    }

    static func makeRecord(
        sessionID: SessionID,
        remote: Remote,
        connectionID: ConnectionID,
        at now: Date,
        capabilities: TransportCapabilities = .ssh
    ) -> SessionRecord {
        SessionRecord(
            id: sessionID,
            remoteID: remote.id,
            connectionID: connectionID,
            title: remote.endpoint,
            state: .connecting,
            capabilities: capabilities,
            createdAt: now,
            lastActiveAt: now
        )
    }

    static func isLive(_ state: TransportState) -> Bool {
        switch state {
        case .disconnected: false
        case .idle, .connecting, .authenticating, .connected, .reconnecting: true
        }
    }
}
