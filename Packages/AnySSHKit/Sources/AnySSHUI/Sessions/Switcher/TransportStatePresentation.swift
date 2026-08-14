import AnySSHCore
import SwiftUI

extension TransportState {
    public var statusColor: Color {
        switch self {
        case .connected:
            Theme.status.online
        case .connecting, .authenticating, .reconnecting:
            Theme.status.busy
        case .disconnected(.failed):
            Theme.status.error
        case .disconnected:
            Theme.status.offline
        case .idle:
            Theme.text.tertiary
        }
    }

    public var label: String {
        switch self {
        case .idle:
            "Idle"
        case .connecting:
            "Connecting"
        case .authenticating:
            "Authenticating"
        case .connected:
            "Connected"
        case .reconnecting:
            "Reconnecting"
        case .disconnected(.failed):
            "Failed"
        case .disconnected:
            "Disconnected"
        }
    }
}
