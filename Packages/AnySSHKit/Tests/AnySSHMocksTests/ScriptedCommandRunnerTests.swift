import AnySSHCore
import Foundation
import Testing

@testable import AnySSHMocks

@Suite struct ScriptedCommandRunnerTests {
    @Test func matchingOnLabelReplaysRecordedBytesAndExitCodes() async throws {
        let runner = ScriptedCommandRunner(specs: [
            .label("ok", bytes: Data("yes".utf8), exitCode: 0),
            .label("fail", bytes: Data("no".utf8), exitCode: 1),
            .label("missing", exitCode: 127),
            .label("capped", bytes: Data(repeating: 0, count: 8), exitCode: 141, truncated: true),
        ])
        let batch = RemoteBatch(commands: [
            RemoteCommand(label: "ok", arguments: ["true"]),
            RemoteCommand(label: "fail", arguments: ["false"]),
            RemoteCommand(label: "missing", arguments: ["nope"]),
            RemoteCommand(label: "capped", arguments: ["cat"], byteCap: 8),
        ])

        let response = try await runner.run(batch)

        #expect(response.sections.map(\.label) == ["ok", "fail", "missing", "capped"])
        #expect(response.sections.map(\.exitCode) == [0, 1, 127, 141])
        #expect(response.sections[0].bytes == Data("yes".utf8))
        #expect(response.sections[3].truncated == true)
        #expect(await runner.openChannelCount == 0)
        #expect(await runner.runs.count == 1)
    }

    @Test func matchingOnArgumentsIgnoresTheLabel() async throws {
        let runner = ScriptedCommandRunner(specs: [
            .arguments(["git", "status"], bytes: Data("clean".utf8))
        ])
        let batch = RemoteBatch(commands: [
            RemoteCommand(label: "status.screen", arguments: ["git", "status"])
        ])

        let response = try await runner.run(batch)

        #expect(response.sections.single?.bytes == Data("clean".utf8))
    }

    @Test func anInjectableFailureThrowsItsState() async throws {
        let runner = ScriptedCommandRunner(specs: [
            .label("repo", failure: .git(.notARepository))
        ])

        await #expect(throws: ErrorState.git(.notARepository)) {
            try await runner.run(
                RemoteBatch(commands: [
                    RemoteCommand(label: "repo", arguments: ["git", "rev-parse"])
                ])
            )
        }
        #expect(await runner.openChannelCount == 0)
    }

    @Test func anInjectableDelayHoldsTheChannelUntilItCompletes() async throws {
        let runner = ScriptedCommandRunner(specs: [
            .label("slow", bytes: Data("done".utf8), delay: .milliseconds(80))
        ])
        let task = Task {
            try await runner.run(
                RemoteBatch(commands: [
                    RemoteCommand(label: "slow", arguments: ["sleep", "1"])
                ])
            )
        }
        #expect(await settles { await runner.openChannelCount == 1 })
        let response = try await task.value
        #expect(response.sections.single?.bytes == Data("done".utf8))
        #expect(await runner.openChannelCount == 0)
    }

    @Test func cancellingDuringADelayThrowsCancelledBySwitch() async throws {
        let runner = ScriptedCommandRunner(specs: [
            .label("hang", delay: .seconds(30))
        ])
        let task = Task {
            try await runner.run(
                RemoteBatch(commands: [
                    RemoteCommand(label: "hang", arguments: ["sleep", "30"])
                ])
            )
        }
        #expect(await settles { await runner.openChannelCount == 1 })
        task.cancel()

        await #expect(throws: ErrorState.transport(.cancelledBySwitch)) {
            try await task.value
        }
        #expect(await runner.openChannelCount == 0)
    }

    @Test func anUnknownCommandIsProgramMissing() async throws {
        let runner = ScriptedCommandRunner(specs: [])
        await #expect(throws: ErrorState.command(.programMissing)) {
            try await runner.run(
                RemoteBatch(commands: [
                    RemoteCommand(label: "none", arguments: ["true"])
                ])
            )
        }
    }
}

extension Array {
    fileprivate var single: Element? {
        count == 1 ? first : nil
    }
}

private func settles(
    within turns: Int = 20_000,
    _ condition: @Sendable () async -> Bool
) async -> Bool {
    for _ in 0..<turns {
        if await condition() { return true }
        await Task.yield()
    }
    return await condition()
}
