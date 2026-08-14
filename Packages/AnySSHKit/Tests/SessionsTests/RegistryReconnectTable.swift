import AnySSHCore

@testable import Sessions

struct RegistryReconnectCase: Sendable, CustomStringConvertible {
    let name: String
    let state: TransportState
    let capabilities: TransportCapabilities
    let expected: SessionReconnectState
    let offersReconnect: Bool

    var description: String {
        name
    }

    static let table = [
        Self(
            name: "idle",
            state: .idle,
            capabilities: RegistryFixture.ssh,
            expected: .idle,
            offersReconnect: false
        ),
        Self(
            name: "connecting",
            state: .connecting,
            capabilities: RegistryFixture.ssh,
            expected: .establishing,
            offersReconnect: false
        ),
        Self(
            name: "authenticating",
            state: .authenticating,
            capabilities: RegistryFixture.ssh,
            expected: .establishing,
            offersReconnect: false
        ),
        Self(
            name: "connected",
            state: .connected,
            capabilities: RegistryFixture.ssh,
            expected: .live,
            offersReconnect: false
        ),
        Self(
            name: "reconnecting",
            state: .reconnecting(attempt: 2),
            capabilities: RegistryFixture.ssh,
            expected: .retrying(attempt: 2),
            offersReconnect: false
        ),
        Self(
            name: "disconnected by the user",
            state: .disconnected(.closedByUser),
            capabilities: RegistryFixture.multiplexed,
            expected: .closed,
            offersReconnect: false
        ),
        Self(
            name: "disconnected by the remote",
            state: .disconnected(.closedByRemote),
            capabilities: RegistryFixture.multiplexed,
            expected: .reconnectable,
            offersReconnect: true
        ),
        Self(
            name: "backgrounded on plain SSH",
            state: .disconnected(.backgrounded),
            capabilities: RegistryFixture.ssh,
            expected: .reconnectable,
            offersReconnect: true
        ),
        Self(
            name: "backgrounded with the work still on the host",
            state: .disconnected(.backgrounded),
            capabilities: RegistryFixture.multiplexed,
            expected: .resumable,
            offersReconnect: true
        ),
        Self(
            name: "cancelled by a session switch",
            state: .disconnected(.cancelledBySwitch),
            capabilities: RegistryFixture.ssh,
            expected: .reconnectable,
            offersReconnect: true
        ),
        Self(
            name: "failed",
            state: .disconnected(.failed(stateID: "transport.connectionRefused")),
            capabilities: RegistryFixture.ssh,
            expected: .failed(stateID: "transport.connectionRefused"),
            offersReconnect: true
        ),
    ]

    static func family(of state: TransportState) -> String {
        switch state {
        case .idle: "idle"
        case .connecting: "connecting"
        case .authenticating: "authenticating"
        case .connected: "connected"
        case .reconnecting: "reconnecting"
        case .disconnected: "disconnected"
        }
    }

    static func reason(of reason: DisconnectReason) -> String {
        switch reason {
        case .closedByUser: "closedByUser"
        case .closedByRemote: "closedByRemote"
        case .backgrounded: "backgrounded"
        case .cancelledBySwitch: "cancelledBySwitch"
        case .failed: "failed"
        }
    }
}
