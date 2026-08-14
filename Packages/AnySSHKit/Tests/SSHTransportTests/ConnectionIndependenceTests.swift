import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: AuthEnvironment.isAvailable))
struct ConnectionIndependenceTests {
    @Test func closingTheDisplayLeavesAControlCommandRunning() async throws {
        let (connection, _) = try await ConnectionTestbed.opened()
        defer { Task { await connection.close() } }

        let task = Task {
            try await LiveSetupRetry.controlRun(channelCounters: {
                (connection.ledger.openCount, connection.ledger.closeCount)
            }) {
                try await connection.run(
                    ConnectionTestbed.batch("slow", ["sh", "-c", "sleep 2; printf alive"])
                )
            }
        }
        #expect(await ConnectionTestbed.eventually { connection.ledger.openCount == 1 })

        await connection.closeDisplay(reason: .closedByRemote)

        let response = try await task.value
        #expect(ConnectionTestbed.text(response, "slow") == "alive")
        #expect(await connection.displayState == .disconnected(.closedByRemote))
        #expect(await connection.controlState == .connected)
        #expect(connection.ledger.openCount == 0)
    }

    @Test func reconnectingTheControlTransportLeavesTheTerminalAlone() async throws {
        let (connection, sink) = try await ConnectionTestbed.opened()
        defer { Task { await connection.close() } }
        _ = try await LiveSetupRetry.controlRun(channelCounters: {
            (connection.ledger.openCount, connection.ledger.closeCount)
        }) {
            try await connection.run(ConnectionTestbed.batch("first", ["true"]))
        }

        let before = await ConnectionTestbed.identities(connection)
        try await connection.reconnectControl()
        let after = await ConnectionTestbed.identities(connection)

        #expect(before.control != nil)
        #expect(after.control != nil)
        #expect(before.control?.localPort != after.control?.localPort)
        #expect(before.display?.localPort == after.display?.localPort)
        #expect(await connection.displayState == .connected)

        try await connection.sendDisplay(Array("printf 'ANYSSH-STILL\\n'\n".utf8)[...])
        #expect(await sink.waitFor("ANYSSH-STILL"))

        let response = try await connection.run(
            ConnectionTestbed.batch("second", ["sh", "-c", "printf back"])
        )
        #expect(ConnectionTestbed.text(response, "second") == "back")
    }

    @Test func reconnectingTheDisplayLeavesTheControlTransportAlone() async throws {
        let (connection, sink) = try await ConnectionTestbed.opened()
        defer { Task { await connection.close() } }
        _ = try await LiveSetupRetry.controlRun(channelCounters: {
            (connection.ledger.openCount, connection.ledger.closeCount)
        }) {
            try await connection.run(ConnectionTestbed.batch("first", ["true"]))
        }

        let before = await ConnectionTestbed.identities(connection)
        try await connection.reconnectDisplay()
        let after = await ConnectionTestbed.identities(connection)

        #expect(before.display?.localPort != after.display?.localPort)
        #expect(before.control?.localPort == after.control?.localPort)
        #expect(await connection.displayState == .connected)
        #expect(await connection.controlState == .connected)

        await sink.clear()
        try await connection.sendDisplay(Array("printf 'ANYSSH-FRESH\\n'\n".utf8)[...])
        #expect(await sink.waitFor("ANYSSH-FRESH"))
    }

    @Test func anIdleControlTransportIsReapedAndRedialledOnDemand() async throws {
        let (connection, _) = try await ConnectionTestbed.opened(idleTTL: .milliseconds(200))
        defer { Task { await connection.close() } }

        _ = try await LiveSetupRetry.controlRun(channelCounters: {
            (connection.ledger.openCount, connection.ledger.closeCount)
        }) {
            try await connection.run(ConnectionTestbed.batch("before", ["true"]))
        }
        let before = await ConnectionTestbed.identities(connection)

        #expect(
            await ConnectionTestbed.eventually {
                await connection.controlState == .disconnected(.backgrounded)
            }
        )
        #expect(await ConnectionTestbed.identities(connection).control == nil)
        #expect(await connection.displayState == .connected)

        let response = try await LiveSetupRetry.controlRun(channelCounters: {
            (connection.ledger.openCount, connection.ledger.closeCount)
        }) {
            try await connection.run(
                ConnectionTestbed.batch("after", ["sh", "-c", "printf again"])
            )
        }
        let after = await ConnectionTestbed.identities(connection)

        #expect(ConnectionTestbed.text(response, "after") == "again")
        #expect(await connection.controlState == .connected)
        #expect(before.control?.localPort != after.control?.localPort)
    }

    @Test func anIdleSweepNeverReapsATransportWithWorkOnIt() async throws {
        let (connection, _) = try await ConnectionTestbed.opened(idleTTL: .milliseconds(500))
        defer { Task { await connection.close() } }

        let task = Task {
            try await LiveSetupRetry.controlRun(channelCounters: {
                (connection.ledger.openCount, connection.ledger.closeCount)
            }) {
                try await connection.run(
                    ConnectionTestbed.batch("busy", ["sh", "-c", "sleep 2; printf busy"])
                )
            }
        }
        #expect(await ConnectionTestbed.eventually { connection.ledger.openCount == 1 })

        let response = try await task.value
        #expect(ConnectionTestbed.text(response, "busy") == "busy")
        #expect(await connection.controlState == .connected)
    }
}
