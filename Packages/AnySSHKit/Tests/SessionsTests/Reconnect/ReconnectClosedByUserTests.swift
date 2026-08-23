import AnySSHCore
import Testing

@testable import Sessions

@Suite struct ReconnectClosedByUserTests {
    private static let roaming = TransportCapabilities(
        roaming: true,
        serverSideResume: true,
        execChannels: false,
        portForwarding: false
    )

    @Test func aSessionClosedByTheUserIsLeftAlone() {
        let decision = ReconnectPolicy().decision(
            state: .disconnected(.closedByUser),
            capabilities: .ssh,
            recordedAttempts: 0
        )

        #expect(decision == .leaveAlone)
        #expect(!decision.shouldDial)
    }

    @Test func recordedAttemptsNeverReviveASessionClosedByTheUser() {
        let decision = ReconnectPolicy().decision(
            state: .disconnected(.closedByUser),
            capabilities: .ssh,
            recordedAttempts: 3
        )

        #expect(decision == .leaveAlone)
    }

    @Test func aRoamingTransportClosedByTheUserIsLeftAlone() {
        let decision = ReconnectPolicy().decision(
            state: .disconnected(.closedByUser),
            capabilities: Self.roaming,
            recordedAttempts: 0
        )

        #expect(decision == .leaveAlone)
    }
}
