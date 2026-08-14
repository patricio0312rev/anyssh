import AnySSHCore
import AnySSHMocks
import Foundation
import Sessions
import Testing

@Suite struct SwitchCancellationTests {
    @Test func switchingCancelsProbeGitBlobAndPollAndDrainsTheirChannels() async throws {
        let connection = MockRemoteConnection(script: .neverFinishing)
        await connection.setDisplayState(.connected)
        let scope = SessionActivityScope(
            sessionID: SessionID(rawValue: "session-a"),
            connection: connection
        )

        let probe = Task { try await scope.run(batch("probe")) }
        let git = Task { try await scope.run(batch("git")) }
        let blob = Task { try await scope.run(batch("blob")) }
        let poll = Task { try await scope.run(batch("poll")) }

        #expect(await settled { await connection.openChannelCount == 4 })

        await scope.cancelAll(reason: .cancelledBySwitch)

        for task in [probe, git, blob, poll] {
            #expect(await cancelledStateID(of: task) == "transport.cancelledBySwitch")
        }
        #expect(await connection.openChannelCount == 0)
        #expect(await connection.displayState == .connected)
        #expect(await scope.cancellations == 1)
    }

    @Test func aCancelledBatchNeverResolvesToAPartialResponse() async throws {
        let connection = MockRemoteConnection(
            script: MockControlScript(
                duration: .seconds(3600),
                sections: ["git": Data("half a response".utf8)]
            )
        )
        await connection.setDisplayState(.connected)
        let scope = SessionActivityScope(
            sessionID: SessionID(rawValue: "session-a"),
            connection: connection
        )

        let git = Task { try await scope.run(batch("git")) }
        #expect(await settled { await connection.openChannelCount == 1 })

        await scope.cancelAll(reason: .cancelledBySwitch)

        #expect(await cancelledStateID(of: git) == "transport.cancelledBySwitch")
        #expect(await connection.openChannelCount == 0)
    }

    @Test func aUserInitiatedDownloadSurvivesTheSwitch() async throws {
        let connection = MockRemoteConnection(
            script: MockControlScript(
                duration: .seconds(2),
                cancelLatency: .milliseconds(10),
                sections: ["download": Data("payload".utf8)]
            )
        )
        await connection.setDisplayState(.connected)
        let scope = SessionActivityScope(
            sessionID: SessionID(rawValue: "session-a"),
            connection: connection
        )

        let download = Task { try await scope.runUserInitiated(batch("download")) }
        let foreground = Task { try await scope.run(batch("probe")) }
        #expect(await settled { await connection.peakChannelCount >= 2 })

        await scope.cancelAll(reason: .cancelledBySwitch)

        #expect(await cancelledStateID(of: foreground) == "transport.cancelledBySwitch")
        let response = try await download.value
        #expect(await connection.openChannelCount == 0)
        #expect(response.sections.first?.bytes == Data("payload".utf8))
    }

    @Test func workThatRacesTheSwitchIsRefusedNotStarted() async throws {
        let connection = MockRemoteConnection(
            script: MockControlScript(
                duration: .seconds(3600),
                cancelLatency: .milliseconds(500)
            )
        )
        await connection.setDisplayState(.connected)
        let scope = SessionActivityScope(
            sessionID: SessionID(rawValue: "session-a"),
            connection: connection
        )
        let foreground = Task { try await scope.run(batch("git")) }
        #expect(await settled { await connection.openChannelCount == 1 })

        let cancelling = Task { await scope.cancelAll(reason: .cancelledBySwitch) }
        try await Task.sleep(for: .milliseconds(50))
        do {
            _ = try await scope.run(batch("late"))
            Issue.record("a batch issued after the switch began must not start")
        } catch let error as ErrorState {
            #expect(error.stateID == "transport.cancelledBySwitch")
        }
        await cancelling.value
        #expect(await cancelledStateID(of: foreground) == "transport.cancelledBySwitch")
    }

    @Test func cancellingTwiceIsIdempotent() async throws {
        let connection = MockRemoteConnection(script: .neverFinishing)
        await connection.setDisplayState(.connected)
        let scope = SessionActivityScope(
            sessionID: SessionID(rawValue: "session-a"),
            connection: connection
        )
        let probe = Task { try await scope.run(batch("probe")) }
        #expect(await settled { await connection.openChannelCount == 1 })

        await scope.cancelAll(reason: .cancelledBySwitch)
        await scope.cancelAll(reason: .cancelledBySwitch)
        await probe.result

        #expect(await connection.openChannelCount == 0)
        #expect(await connection.displayState == .connected)
        #expect(await scope.cancellations == 2)
    }

    private func batch(_ label: String) -> RemoteBatch {
        RemoteBatch(commands: [RemoteCommand(label: label, arguments: ["true"])])
    }

    private func settled(_ condition: () async -> Bool) async -> Bool {
        let deadline = ContinuousClock.now + .seconds(5)
        while ContinuousClock.now < deadline {
            if await condition() { return true }
            await Task.yield()
        }
        return false
    }

    private func cancelledStateID(of task: Task<BatchResponse, any Error>) async -> String? {
        switch await task.result {
        case .failure(let error as ErrorState): error.stateID
        case .failure: nil
        case .success: nil
        }
    }
}
