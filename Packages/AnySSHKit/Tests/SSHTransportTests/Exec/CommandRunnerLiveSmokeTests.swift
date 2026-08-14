import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: LiveHost.isDevelopmentHostReachable))
struct CommandRunnerLiveSmokeTests {
    @Test func sixCommandBatchAgainstTheLiveHostRecordsElapsedTime() async throws {
        let (runner, connection) = try await CommandRunnerFixture.liveRunner()
        defer { Task { await connection.close() } }

        let started = ContinuousClock.now
        let response = try await runner.run(CommandRunnerFixture.sixCommandBatch)
        let elapsed = started.duration(to: .now)

        try LiveArtifact.write(
            "live-p29.json",
            [
                "host": LiveHost.development.host,
                "user": LiveHost.development.username,
                "labels": response.sections.map(\.label),
                "exitCodes": response.sections.map { Int($0.exitCode) },
                "sectionBytes": response.sections.map(\.bytes.count),
                "truncated": response.sections.map(\.truncated),
                "elapsedMilliseconds": elapsed.milliseconds,
                "peakOpenChannels": await runner.connectionPeakOpenCount,
                "openChannelsAfter": await runner.connectionOpenChannelCount,
                "recordedAt": ISO8601DateFormatter().string(from: Date()),
            ]
        )

        #expect(response.sections.map(\.exitCode) == CommandRunnerFixture.expectedExitCodes)
        #expect(await runner.connectionOpenChannelCount == 0)
    }
}
