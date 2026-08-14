import AnySSHCore
import Foundation
import Testing

@testable import AnySSHCore

@Suite
struct RecentDirectoriesBatchTests {
    @Test func scanIssuesExactlyOneRunnerCall() async throws {
        let bytes = try RecentDirectoriesFixtureData.bytes("host-scan-merged.txt")
        let runner = RecentsRecordingRunner(bytes: bytes)
        let probe = SSHRecentDirectoriesProbe(runner: runner)
        let list = try await probe.list(limit: 10)
        #expect(runner.batches.count == 1)
        #expect(runner.batches[0].commands.count == 1)
        #expect(runner.batches[0].commands[0].label == RecentDirectoriesCommand.label)
        #expect(runner.batches[0].commands[0].arguments[0] == "sh")
        #expect(list.first?.path == "/home/dev/src/api")
    }

    @Test func commandIsOneShellScriptWithoutNestedLoginShell() {
        let command = RecentDirectoriesCommand.batch().commands[0]
        #expect(command.arguments.count == 3)
        #expect(command.arguments[0] == "sh")
        #expect(command.arguments[1] == "-c")
        #expect(command.arguments[2].contains(RecentDirectoriesCommand.protocolVersion))
        #expect(!command.arguments[2].contains(" -lc "))
        #expect(command.arguments[2].contains("history.jsonl"))
        #expect(command.arguments[2].contains("rollout-"))
        #expect(command.arguments[2].contains("opencode.db"))
        #expect(command.arguments[2].contains(".cursor/projects"))
    }

    @Test func missingSectionIsAnErrorAndEmptyBytesParseToEmptyList() async throws {
        let emptyRunner = RecentsRecordingRunner(sections: [])
        let probe = SSHRecentDirectoriesProbe(runner: emptyRunner)
        await #expect(throws: RecentDirectoriesProbeError.missingResponse) {
            _ = try await probe.list(limit: 5)
        }

        let headerOnly = Data("anyssh-recents/1\n".utf8)
        let ok = try RecentDirectoriesParser().parse(headerOnly, limit: 5)
        #expect(ok.isEmpty)
    }

    @Test func failedExitIsSurfaced() async throws {
        let runner = RecentsRecordingRunner(
            bytes: Data("anyssh-recents/1\n".utf8),
            exitCode: 2
        )
        let probe = SSHRecentDirectoriesProbe(runner: runner)
        await #expect(throws: RecentDirectoriesProbeError.commandFailed(2)) {
            _ = try await probe.list(limit: 5)
        }
    }
}

final class RecentsRecordingRunner: RemoteCommandRunner, @unchecked Sendable {
    private let response: BatchResponse
    private let lock = NSLock()
    private var recorded = [RemoteBatch]()

    init(bytes: Data, exitCode: Int32 = 0) {
        response = BatchResponse(sections: [
            CommandSection(
                label: RecentDirectoriesCommand.label,
                bytes: bytes,
                exitCode: exitCode,
                truncated: exitCode == 141
            )
        ])
    }

    init(sections: [CommandSection]) {
        response = BatchResponse(sections: sections)
    }

    var batches: [RemoteBatch] {
        lock.withLock { recorded }
    }

    func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        lock.withLock { recorded.append(batch) }
        return response
    }
}
