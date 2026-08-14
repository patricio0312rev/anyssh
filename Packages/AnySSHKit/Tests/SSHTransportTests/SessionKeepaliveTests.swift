import Foundation
import Testing

@testable import SSHTransport

@Suite struct SessionKeepaliveTests {
    @Test(arguments: [Duration.seconds(1), Duration.seconds(3)])
    func aHandshakeAgainstASilentHostEndsAfterItsWindow(window: Duration) async throws {
        let listener = try #require(LocalListener(host: "127.0.0.1"))
        defer { listener.close() }

        let session = SSHSession(
            target: SessionTarget(host: "127.0.0.1", port: listener.port),
            configuration: SSHSessionConfiguration(handshakeTimeout: window)
        )

        let outcome = await BoundedRun.run(ceiling: window + .seconds(120)) {
            try await session.open()
        }
        let waits = await session.diagnostics.eagainRetries
        let budget = Int(window / SSHSession.waitSlice) + 4

        #expect(outcome == .failed(.keepaliveTimeout))
        #expect(waits <= budget, "waited \(waits) slices for a \(window) window")
        #expect(waits >= 1, "the loop never waited at all")
        #expect(
            await session.state == .disconnected(.failed(stateID: "transport.keepaliveTimeout")))
        await session.close()
    }

    @Test func anEstablishedSessionPastItsDeadPeerWindowStopsBeforeTheWire() async throws {
        let listener = try #require(LocalListener(host: "127.0.0.1"))
        defer { listener.close() }

        let session = SSHSession(
            target: SessionTarget(host: "127.0.0.1", port: listener.port),
            configuration: SSHSessionConfiguration(
                handshakeTimeout: .seconds(3600),
                deadPeerTimeout: .zero
            )
        )
        try await session.dial()
        try await session.startSession()
        try #require(await session.timeSinceLastInbound > .zero)

        await #expect(throws: TransportFailure.keepaliveTimeout) {
            try await session.sendKeepalive()
        }

        #expect(await session.diagnostics.eagainRetries == 0, "it reached the socket anyway")
        #expect(
            await session.state == .disconnected(.failed(stateID: "transport.keepaliveTimeout")))
        await session.close()
    }

    @Test func keepaliveOnASessionThatNeverHandshookIsNotConnected() async {
        let session = SSHSession(target: SessionTarget(host: "127.0.0.1", port: 22))
        await #expect(throws: TransportFailure.notConnected) { try await session.sendKeepalive() }
    }

    @Suite(.enabled(if: AvailableSSHHost.isAvailable))
    struct AgainstARealServer {
        @Test func keepaliveSucceedsOnALiveSession() async throws {
            let endpoint = try #require(AvailableSSHHost.endpoint)
            let session = SSHSession(
                target: SessionTarget(host: endpoint.host, port: endpoint.port),
                trust: TestTrust.acceptingFirstUse()
            )
            try await session.open()

            let sleepBudget = try await session.sendKeepalive()
            #expect(sleepBudget > .zero)
            #expect(await session.diagnostics.errorCodes.isEmpty)
            await session.close()
        }

        @Test func silenceLongerThanTheWindowReportsADeadPeer() async throws {
            let endpoint = try #require(AvailableSSHHost.endpoint)
            let session = SSHSession(
                target: SessionTarget(host: endpoint.host, port: endpoint.port),
                configuration: SSHSessionConfiguration(
                    handshakeTimeout: .seconds(30),
                    deadPeerTimeout: .seconds(1)
                ),
                trust: TestTrust.acceptingFirstUse()
            )
            try await session.open()
            try await Task.sleep(for: .seconds(2))

            await #expect(throws: TransportFailure.keepaliveTimeout) {
                try await session.sendKeepalive()
            }
            await session.close()
        }
    }
}
