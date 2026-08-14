import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: AuthEnvironment.isAvailable))
struct ConnectionPairTests {
    @Test func onePairHoldsTwoDistinctAuthenticatedConnections() async throws {
        let (connection, sink) = try await ConnectionTestbed.opened()
        defer { Task { await connection.close() } }

        let response = try await LiveSetupRetry.controlRun(channelCounters: {
            (connection.ledger.openCount, connection.ledger.closeCount)
        }) {
            try await connection.run(
                ConnectionTestbed.batch("client", ConnectionTestbed.clientReport)
            )
        }
        let controlPort = ConnectionTestbed.reportedClientPort(
            ConnectionTestbed.text(response, "client")
        )
        let displayPort = try await displayClientPort(connection, sink)
        let identities = await ConnectionTestbed.identities(connection)

        #expect(identities.display != nil)
        #expect(identities.control != nil)
        #expect(identities.display?.handleAddress != identities.control?.handleAddress)
        #expect(identities.display?.descriptor != identities.control?.descriptor)
        #expect(controlPort != nil)
        #expect(displayPort != nil)
        #expect(controlPort != displayPort)
        #expect(identities.display?.localPort != identities.control?.localPort)
        #expect(await connection.displayState == .connected)
        #expect(await connection.controlState == .connected)
    }

    @Test func theServerSeesBothConnectionsAtOnce() async throws {
        let (connection, _) = try await ConnectionTestbed.opened()
        defer { Task { await connection.close() } }

        let response = try await LiveSetupRetry.controlRun(channelCounters: {
            (connection.ledger.openCount, connection.ledger.closeCount)
        }) {
            try await connection.run(
                ConnectionTestbed.batch("tcp", ["cat", "/proc/net/tcp"])
            )
        }
        let port = AuthEnvironment.testbed?.port ?? Int(TestbedHost.sshd.port)
        let established = ConnectionTestbed.establishedSSHConnections(
            ConnectionTestbed.text(response, "tcp"),
            port: port
        )

        #expect(established >= 2)
    }

    @Test func theControlTransportIsNotDialledUntilThereIsControlWork() async throws {
        let (connection, _) = try await ConnectionTestbed.opened()
        defer { Task { await connection.close() } }

        #expect(await connection.displayState == .connected)
        #expect(await connection.controlState == .idle)
        #expect(await ConnectionTestbed.identities(connection).control == nil)

        _ = try await LiveSetupRetry.controlRun(channelCounters: {
            (connection.ledger.openCount, connection.ledger.closeCount)
        }) {
            try await connection.run(ConnectionTestbed.batch("id", ["id", "-un"]))
        }

        #expect(await connection.controlState == .connected)
        #expect(await ConnectionTestbed.identities(connection).control != nil)
    }

    @Test func bothTransportsShareOneResolvedCredential() async throws {
        let credentials = ConnectionCredentials {
            .privateKey(AuthSupport.key(AuthEnvironment.ed25519))
        }
        let connection = ConnectionTestbed.connection(credentials: credentials)
        await connection.setDisplaySink(ShellSink())
        await connection.setDisplayDelegate(DisplayDelegate())
        defer { Task { await connection.close() } }

        try await connection.startDisplay(size: TerminalSize(columns: 80, rows: 24))
        let response = try await connection.run(ConnectionTestbed.batch("id", ["id", "-un"]))

        #expect(ConnectionTestbed.text(response, "id") == "keyuser")
        #expect(await credentials.resolutions == 1)
        #expect(await credentials.issued == 2)
        #expect(await connection.notes.isEmpty)
    }

    private func displayClientPort(
        _ connection: SSHRemoteConnection,
        _ sink: ShellSink
    ) async throws -> Int? {
        try await connection.sendDisplay(
            Array("stty -onlcr -echo; PS1=''; printf 'ANYSSH-GO\\n'\n".utf8)[...]
        )
        #expect(await sink.waitFor("ANYSSH-GO\n"))
        await sink.clear()

        try await connection.sendDisplay(Array("printf '%s' \"$SSH_CLIENT\"\n".utf8)[...])
        #expect(await sink.waitFor(" "))
        return ConnectionTestbed.reportedClientPort(await sink.text)
    }
}
