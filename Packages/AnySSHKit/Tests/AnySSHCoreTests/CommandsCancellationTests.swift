import Foundation
import Testing

@testable import AnySSHCore

@Suite struct CommandCancellationTests {
    private static let batch = RemoteBatch(commands: [
        RemoteCommand(label: "repo.root", arguments: ["git", "rev-parse", "--show-toplevel"])
    ])

    @Test func cancellingARunClosesItsChannelRatherThanLeakingIt() async throws {
        let ledger = ChannelLedger()
        let runner = ContractRunner(ledger: ledger)
        let task = Task { try await runner.run(Self.batch) }
        #expect(await waitUntil { ledger.openCount == 1 })

        task.cancel()

        #expect(await waitUntil { ledger.openCount == 0 })
        #expect(ledger.closeCount == 1)
        await #expect(throws: ErrorState.transport(.cancelledBySwitch)) { try await task.value }
    }

    @Test func aCancelledRunNeverReturnsAPartialResponse() async throws {
        let ledger = ChannelLedger()
        let runner = ContractRunner(ledger: ledger)
        let task = Task { try await runner.run(Self.batch) }
        #expect(await waitUntil { ledger.openCount == 1 })

        task.cancel()

        let result = await task.result
        #expect(throws: (any Error).self) { try result.get() }
    }

    @Test func fiveInFlightRunsAllReturnTheirChannels() async throws {
        let ledger = ChannelLedger()
        let runner = ContractRunner(ledger: ledger)
        let tasks = (0..<5).map { _ in Task { try await runner.run(Self.batch) } }
        #expect(await waitUntil { ledger.openCount == 5 })

        for task in tasks { task.cancel() }

        #expect(await waitUntil { ledger.openCount == 0 })
        #expect(ledger.closeCount == 5)
        for task in tasks {
            await #expect(throws: ErrorState.transport(.cancelledBySwitch)) { try await task.value }
        }
    }

    @Test func cancellationIsIdempotent() async throws {
        let ledger = ChannelLedger()
        let runner = ContractRunner(ledger: ledger)
        let task = Task { try await runner.run(Self.batch) }
        #expect(await waitUntil { ledger.openCount == 1 })

        task.cancel()
        task.cancel()
        _ = await task.result
        task.cancel()

        #expect(ledger.closeCount == 1)
        #expect(ledger.openCount == 0)
    }

    @Test func aRunInsideAnAlreadyCancelledTaskLeavesNothingOpen() async throws {
        let ledger = ChannelLedger()
        let runner = ContractRunner(ledger: ledger)
        let task = Task { try await runner.run(Self.batch) }

        task.cancel()
        _ = await task.result

        #expect(ledger.openCount == 0)
        #expect(ledger.closeCount == 1)
    }

    @Test func aRunnerWithoutTheHandlerIsCaughtLeaking() async throws {
        let ledger = ChannelLedger()
        let runner = LeakingRunner(ledger: ledger)
        let task = Task { try await runner.run(Self.batch) }
        #expect(await waitUntil { ledger.openCount == 1 })

        task.cancel()
        _ = await task.result

        #expect(ledger.openCount == 1)
        #expect(ledger.closeCount == 0)
    }

    private func waitUntil(
        within turns: Int = 10_000,
        _ condition: @Sendable () -> Bool
    ) async -> Bool {
        for _ in 0..<turns {
            if condition() { return true }
            await Task.yield()
        }
        return condition()
    }
}
