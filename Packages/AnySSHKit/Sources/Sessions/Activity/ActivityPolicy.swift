import AnySSHCore
import Foundation

public struct ActivityPolicy: Sendable {
    public let staleAfter: TimeInterval

    public init(staleAfter: TimeInterval = 60) {
        self.staleAfter = staleAfter
    }

    public func content(
        for record: SessionRecord,
        remoteName: String,
        notification: String? = nil,
        agentState: String = "idle",
        at now: Date
    ) -> ActivityContent {
        ActivityContent(
            sessionID: record.id,
            title: record.title,
            remoteName: remoteName,
            transportState: stateName(record.state),
            agentState: agentState,
            uptime: max(0, now.timeIntervalSince(record.createdAt)),
            notification: notification,
            updatedAt: now,
            staleDate: now.addingTimeInterval(staleAfter)
        )
    }

    private func stateName(_ state: TransportState) -> String {
        switch state {
        case .idle: "idle"
        case .connecting: "connecting"
        case .authenticating: "authenticating"
        case .connected: "connected"
        case .reconnecting: "reconnecting"
        case .disconnected: "disconnected"
        }
    }
}
