import AnySSHCore
import Foundation
import Testing

@testable import AnySSHMocks

@Suite struct MockRemoteConnectionTests {
    private static let batch = RemoteBatch(commands: [
        RemoteCommand(label: "repo.root", arguments: ["git", "rev-parse", "--show-toplevel"])
    ])

    @Test func aScriptedBatchAnswersItsRecordedBytes() async throws {
        let connection = MockRemoteConnection(
            script: MockControlScript(sections: ["repo.root": Data("/srv/app".utf8)])
        )

        let response = try await connection.run(Self.batch)

        #expect(response.sections.map(\.label) == ["repo.root"])
        #expect(response.sections.first?.bytes == Data("/srv/app".utf8))
        #expect(await connection.openChannelCount == 0)
        #expect(await connection.completedRuns == 1)
        #expect(await connection.controlState == .connected)
    }

    @Test func aScriptedFailureThrowsItsState() async throws {
        let connection = MockRemoteConnection(
            script: MockControlScript(failures: ["repo.root": .git(.notARepository)])
        )

        await #expect(throws: ErrorState.git(.notARepository)) {
            try await connection.run(Self.batch)
        }
        #expect(await connection.openChannelCount == 0)
    }

    @Test func cancellingFourBatchesClosesFourChannels() async throws {
        let connection = MockRemoteConnection(script: .neverFinishing)
        await connection.setDisplayState(.connected)

        let tasks = (0..<4).map { _ in Task { try await connection.run(Self.batch) } }
        #expect(await settles { await connection.openChannelCount == 4 })

        await connection.cancelAll(reason: .cancelledBySwitch)

        #expect(await connection.openChannelCount == 0)
        #expect(await connection.peakChannelCount == 4)
        for task in tasks {
            await #expect(throws: ErrorState.transport(.cancelledBySwitch)) {
                try await task.value
            }
        }
        #expect(await connection.displayState == .connected)
        #expect(await connection.lastCancellationReason == .cancelledBySwitch)
    }

    @Test func cancellationWaitsForTheInjectedLatency() async throws {
        let connection = MockRemoteConnection(
            script: MockControlScript(duration: .seconds(3600), cancelLatency: .milliseconds(120))
        )
        let task = Task { try await connection.run(Self.batch) }
        #expect(await settles { await connection.openChannelCount == 1 })

        let cancelling = ContinuousClock.now
        await connection.cancelAll(reason: .cancelledBySwitch)
        let elapsed = cancelling.duration(to: .now)

        #expect(elapsed >= .milliseconds(120))
        #expect(await connection.openChannelCount == 0)
        await #expect(throws: ErrorState.transport(.cancelledBySwitch)) { try await task.value }
    }

    @Test func cancellationIsIdempotentAndSafeWhenNothingIsRunning() async throws {
        let connection = MockRemoteConnection()

        await connection.cancelAll(reason: .cancelledBySwitch)
        await connection.cancelAll(reason: .backgrounded)

        #expect(await connection.cancellations == 2)
        #expect(await connection.lastCancellationReason == .backgrounded)
        #expect(await connection.openChannelCount == 0)
    }

    @Test func aClosedConnectionRefusesFurtherWork() async throws {
        let connection = MockRemoteConnection()
        await connection.close(reason: .closedByUser)

        await #expect(throws: (any Error).self) { try await connection.run(Self.batch) }
        #expect(await connection.displayState == .disconnected(.closedByUser))
    }

    private func settles(
        within turns: Int = 10_000,
        _ condition: @Sendable () async -> Bool
    ) async -> Bool {
        for _ in 0..<turns {
            if await condition() { return true }
            await Task.yield()
        }
        return await condition()
    }
}
