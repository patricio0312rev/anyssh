import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: LiveHost.isDevelopmentHostReachable))
struct ConnectionLiveSmokeTests {
    @Test func opensAPairAgainstTheLiveHostAndRecordsBothClientPorts() async throws {
        let host = LiveHost.development
        let sink = ShellSink()
        let connection = SSHRemoteConnection(
            profile: ConnectionProfile(
                connectionID: ConnectionID(rawValue: "live-p13"),
                target: SessionTarget(host: host.host, port: Int(host.port)),
                username: host.username,
                display: DisplayTransportConfiguration(session: AuthSupport.patient),
                control: AuthSupport.patient
            ),
            credentials: ConnectionCredentials(
                .privateKey(AuthSupport.key(host.privateKeyPath))
            ),
            hostKeys: MemoryHostKeyStore()
        )
        await connection.setDisplaySink(sink)
        await connection.setDisplayDelegate(DisplayDelegate())

        try await connection.startDisplay(size: TerminalSize(columns: 100, rows: 40))
        let dialling = ContinuousClock.now
        let report = try await connection.run(
            ConnectionTestbed.batch("client", ConnectionTestbed.clientReport)
        )
        let controlDial = dialling.duration(to: .now)

        let identities = await ConnectionTestbed.identities(connection)
        let cancellation = try await measureCancellation(connection)

        try LiveArtifact.write(
            "live-p13.json",
            [
                "host": host.host,
                "user": host.username,
                "displayClientPort": identities.display?.localPort ?? -1,
                "controlClientPort": identities.control?.localPort ?? -1,
                "serverReportedControlClient": ConnectionTestbed.text(report, "client"),
                "distinctSessions": identities.display?.handleAddress
                    != identities.control?.handleAddress,
                "controlDialMilliseconds": controlDial.milliseconds,
                "cancelFourChannelsMilliseconds": cancellation.milliseconds,
                "openChannelsAfterCancel": connection.ledger.openCount,
                "peakOpenChannels": connection.ledger.peakOpenCount,
                "recordedAt": ISO8601DateFormatter().string(from: Date()),
            ]
        )

        #expect(identities.display?.localPort != identities.control?.localPort)
        #expect(connection.ledger.openCount == 0)
        await connection.close()
    }

    private func measureCancellation(_ connection: SSHRemoteConnection) async throws -> Duration {
        let tasks = (0..<4).map { index in
            Task { try await connection.run(ConnectionTestbed.sleeping("live-\(index)")) }
        }
        #expect(await ConnectionTestbed.eventually { connection.ledger.openCount == 4 })

        let cancelling = ContinuousClock.now
        await connection.cancelAll(reason: .cancelledBySwitch)
        let elapsed = cancelling.duration(to: .now)

        for task in tasks {
            #expect(
                await ConnectionTestbed.stateID(of: task)
                    == ErrorState.transport(.cancelledBySwitch).stateID
            )
        }
        return elapsed
    }
}
