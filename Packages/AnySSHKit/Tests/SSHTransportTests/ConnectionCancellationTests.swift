import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: AuthEnvironment.isAvailable))
struct ConnectionCancellationTests {
    @Test func fourInFlightCommandsAllThrowAndReturnTheirChannels() async throws {
        let (connection, _) = try await ConnectionTestbed.opened()
        defer { Task { await connection.close() } }
        _ = try await LiveSetupRetry.controlRun(channelCounters: {
            (connection.ledger.openCount, connection.ledger.closeCount)
        }) {
            try await connection.run(ConnectionTestbed.batch("warm", ["true"]))
        }

        let tasks = (0..<4).map { index in
            Task { try await connection.run(ConnectionTestbed.sleeping("sleep-\(index)")) }
        }
        #expect(await ConnectionTestbed.eventually { connection.ledger.openCount == 4 })

        let cancelling = ContinuousClock.now
        await connection.cancelAll(reason: .cancelledBySwitch)
        let elapsed = cancelling.duration(to: .now)

        #expect(connection.ledger.openCount == 0)
        for task in tasks {
            #expect(
                await ConnectionTestbed.stateID(of: task)
                    == ErrorState.transport(.cancelledBySwitch).stateID
            )
        }

        let response = try await connection.run(
            ConnectionTestbed.batch("after", ["sh", "-c", "printf ok"])
        )
        #expect(ConnectionTestbed.text(response, "after") == "ok")
        #expect(await connection.displayState == .connected)
        #expect(await connection.controlState == .connected)
        #expect(elapsed < .seconds(10))
    }

    @Test func aCancelledBatchNeverResolvesToAPartialResponse() async throws {
        let (connection, _) = try await ConnectionTestbed.opened()
        defer { Task { await connection.close() } }

        let task = Task {
            try await LiveSetupRetry.controlRun(channelCounters: {
                (connection.ledger.openCount, connection.ledger.closeCount)
            }) {
                try await connection.run(
                    RemoteBatch(commands: [
                        RemoteCommand(label: "early", arguments: ["sh", "-c", "printf first"]),
                        RemoteCommand(label: "late", arguments: ["sleep", "10"]),
                    ])
                )
            }
        }
        #expect(await ConnectionTestbed.eventually { connection.ledger.openCount == 1 })

        await connection.cancelAll(reason: .cancelledBySwitch)

        let result = await task.result
        #expect(throws: (any Error).self) { try result.get() }
        #expect(
            await ConnectionTestbed.stateID(of: task)
                == ErrorState.transport(.cancelledBySwitch).stateID
        )
        #expect(connection.ledger.openCount == 0)
    }

    @Test func cancellingTheCallerClosesTheChannelToo() async throws {
        let (connection, _) = try await ConnectionTestbed.opened()
        defer { Task { await connection.close() } }

        let task = Task {
            try await LiveSetupRetry.controlRun(channelCounters: {
                (connection.ledger.openCount, connection.ledger.closeCount)
            }) {
                try await connection.run(ConnectionTestbed.sleeping("caller"))
            }
        }
        #expect(await ConnectionTestbed.eventually { connection.ledger.openCount == 1 })

        task.cancel()

        #expect(
            await ConnectionTestbed.stateID(of: task)
                == ErrorState.transport(.cancelledBySwitch).stateID
        )
        #expect(await ConnectionTestbed.eventually { connection.ledger.openCount == 0 })
    }

    @Test func cancellingTwiceClosesNothingTwice() async throws {
        let (connection, _) = try await ConnectionTestbed.opened()
        defer { Task { await connection.close() } }

        let task = Task {
            try await LiveSetupRetry.controlRun(channelCounters: {
                (connection.ledger.openCount, connection.ledger.closeCount)
            }) {
                try await connection.run(ConnectionTestbed.sleeping("twice"))
            }
        }
        #expect(await ConnectionTestbed.eventually { connection.ledger.openCount == 1 })

        await connection.cancelAll(reason: .cancelledBySwitch)
        await connection.cancelAll(reason: .cancelledBySwitch)
        _ = await task.result
        await connection.cancelAll(reason: .cancelledBySwitch)

        #expect(connection.ledger.closeCount == 1)
        #expect(connection.ledger.openCount == 0)
        #expect(await connection.cancellations == 3)
    }
}
