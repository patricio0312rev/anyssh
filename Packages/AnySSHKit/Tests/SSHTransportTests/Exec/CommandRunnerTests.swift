import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: AuthEnvironment.isAvailable))
struct CommandRunnerTests {
    @Test func sixCommandsReturnLabelledSectionsWithExactExitCodes() async throws {
        let (runner, connection) = try await CommandRunnerFixture.runner()
        defer { Task { await connection.close() } }

        let response = try await LiveSetupRetry.controlRun(channelCounters: {
            (connection.ledger.openCount, connection.ledger.closeCount)
        }) {
            try await runner.run(CommandRunnerFixture.sixCommandBatch)
        }

        #expect(response.sections.map(\.label) == CommandRunnerFixture.sixCommandBatch.commands.map(\.label))
        #expect(response.sections.map(\.exitCode) == CommandRunnerFixture.expectedExitCodes)
        #expect(response.sections[1].bytes == Data("ready".utf8))
        #expect(response.sections[5].truncated == true)
        #expect(response.sections[5].bytes.count == 64)
        #expect(await runner.connectionOpenChannelCount == 0)
        #expect(await runner.connectionPeakOpenCount == 1)
    }

    @Test func tenConcurrentBatchesNeverExceedFourChannels() async throws {
        let (runner, connection) = try await CommandRunnerFixture.runner()
        defer { Task { await connection.close() } }
        _ = try await LiveSetupRetry.controlRun(channelCounters: {
            (connection.ledger.openCount, connection.ledger.closeCount)
        }) {
            try await runner.run(ConnectionTestbed.batch("warm", ["true"]))
        }

        let tasks = (0..<10).map { index in
            Task {
                try await runner.run(
                    ConnectionTestbed.batch("load-\(index)", ["sh", "-c", "sleep 0.2; printf ok"])
                )
            }
        }
        var responses = [BatchResponse]()
        for task in tasks {
            responses.append(try await task.value)
        }

        #expect(responses.count == 10)
        #expect(await runner.peakOpenCount == 4)
        #expect(await runner.connectionPeakOpenCount <= 4)
        #expect(await runner.openChannelCount == 0)
        #expect(await runner.connectionOpenChannelCount == 0)
        for (index, response) in responses.enumerated() {
            #expect(ConnectionTestbed.text(response, "load-\(index)") == "ok")
        }
    }

    @Test func cancellingFiveInFlightBatchesClosesEveryChannel() async throws {
        let (runner, connection) = try await CommandRunnerFixture.runner()
        defer { Task { await connection.close() } }
        _ = try await LiveSetupRetry.controlRun(channelCounters: {
            (connection.ledger.openCount, connection.ledger.closeCount)
        }) {
            try await runner.run(ConnectionTestbed.batch("warm", ["true"]))
        }

        let tasks = (0..<5).map { index in
            Task { try await runner.run(ConnectionTestbed.sleeping("sleep-\(index)")) }
        }
        #expect(await ConnectionTestbed.eventually { await runner.openChannelCount == 4 })
        #expect(await ConnectionTestbed.eventually { await connection.gate.waiterCount == 1 })

        await connection.cancelAll(reason: .cancelledBySwitch)

        for task in tasks {
            #expect(
                await CommandRunnerFixture.stateID(of: task)
                    == ErrorState.transport(.cancelledBySwitch).stateID
            )
        }
        #expect(
            await ConnectionTestbed.eventually {
                let connectionOpen = await runner.connectionOpenChannelCount
                let runnerOpen = await runner.openChannelCount
                return connectionOpen == 0 && runnerOpen == 0
            }
        )
        #expect(await runner.connectionOpenChannelCount == 0)
        #expect(await runner.openChannelCount == 0)
    }

    @Test func aQueuedBatchIsCancelledBySwitchRatherThanRunningAfterwards() async throws {
        let (runner, connection) = try await CommandRunnerFixture.runner()
        defer { Task { await connection.close() } }
        _ = try await LiveSetupRetry.controlRun(channelCounters: {
            (connection.ledger.openCount, connection.ledger.closeCount)
        }) {
            try await runner.run(ConnectionTestbed.batch("warm", ["true"]))
        }

        let holders = (0..<4).map { index in
            Task { try await runner.run(ConnectionTestbed.sleeping("hold-\(index)", seconds: 5)) }
        }
        #expect(await ConnectionTestbed.eventually { await runner.openChannelCount == 4 })

        let queued = Task {
            try await runner.run(ConnectionTestbed.batch("after-switch", ["printf", "%s", "late"]))
        }
        #expect(await ConnectionTestbed.eventually { await connection.gate.waiterCount == 1 })

        await connection.cancelAll(reason: .cancelledBySwitch)

        #expect(
            await CommandRunnerFixture.stateID(of: queued)
                == ErrorState.transport(.cancelledBySwitch).stateID
        )
        for task in holders {
            #expect(
                await CommandRunnerFixture.stateID(of: task)
                    == ErrorState.transport(.cancelledBySwitch).stateID
            )
        }
        #expect(await runner.openChannelCount == 0)
        #expect(await runner.connectionOpenChannelCount == 0)
    }

    @Test func aBinaryBlobNeverSharesAChannelWithABatch() async throws {
        let (runner, connection) = try await CommandRunnerFixture.runner()
        defer { Task { await connection.close() } }

        _ = try await runner.run(ConnectionTestbed.batch("batch", ["printf", "%s", "framed"]))
        let batchChannel = await runner.lastBatchChannelID

        let bytes = try await runner.executeRaw("printf '%s' raw-blob")
        let rawChannel = await runner.lastRawChannelID

        #expect(batchChannel != nil)
        #expect(rawChannel != nil)
        #expect(batchChannel != rawChannel)
        #expect(bytes == Data("raw-blob".utf8))
        #expect(await runner.connectionOpenChannelCount == 0)
    }

    @Test func aFifthRequestTimesOutWhenTheQueueIsPinnedFull() async throws {
        let (runner, connection) = try await CommandRunnerFixture.runner(
            queueTimeout: .milliseconds(200)
        )
        defer { Task { await connection.close() } }
        _ = try await LiveSetupRetry.controlRun(channelCounters: {
            (connection.ledger.openCount, connection.ledger.closeCount)
        }) {
            try await runner.run(ConnectionTestbed.batch("warm", ["true"]))
        }

        let holders = (0..<4).map { index in
            Task { try await runner.run(ConnectionTestbed.sleeping("hold-\(index)", seconds: 5)) }
        }
        #expect(await ConnectionTestbed.eventually { await runner.openChannelCount == 4 })

        let failure = await ConnectionTestbed.failure {
            _ = try await runner.run(ConnectionTestbed.batch("overflow", ["true"]))
        }
        #expect(failure?.stateID == TransportFailure.channelQueueTimeout.stateID)

        for task in holders { task.cancel() }
        for task in holders { _ = await task.result }
        #expect(await ConnectionTestbed.eventually { await runner.openChannelCount == 0 })
    }
}
