#if os(macOS)
import Foundation
import Testing

@testable import AnySSHCore

@Suite struct LocalBatchExecutionTests {
    private static let batch = RemoteBatch(commands: [
        RemoteCommand(label: "path.echo", arguments: ["printf", "%s", HostileInput.path]),
        RemoteCommand(label: "blob.nul", arguments: ["head", "-c", "4096", "/dev/zero"]),
        RemoteCommand(label: "git.missing", arguments: ["anyssh-definitely-not-a-program"]),
        RemoteCommand(label: "diff.capped", arguments: ["/bin/cat", "/dev/zero"], byteCap: 4096),
        RemoteCommand(label: "stderr.merged", arguments: ["/bin/sh", "-c", "printf err >&2; exit 3"]),
        RemoteCommand(label: "repo.root", arguments: ["printf", "%s", "/srv/repo"]),
    ])

    private func runBatch() throws -> BatchResponse {
        let rendered = BatchScriptBuilder().render(Self.batch)
        let outcome = try CommandsSubprocess.sh(
            rendered.command,
            overrides: CommandsSubprocess.quietZshEnvironment
        )
        return try BatchResponseParser(nonce: rendered.nonce, batch: Self.batch).parse(outcome.stdout)
    }

    @Test func sixCommandsComeBackAsSixLabelledSectionsInOneRun() throws {
        let parsed = try runBatch()

        #expect(parsed.sections.map(\.label) == Self.batch.commands.map(\.label))
        #expect(parsed.sections.map(\.exitCode) == [0, 0, 127, 141, 3, 0])
        #expect(parsed.sections.map(\.truncated) == [false, false, false, true, false, false])
        #expect(parsed.sections.map(\.failed) == [false, false, true, false, true, false])
    }

    @Test func thePathologicalPathRoundTripsThroughBothLevelsOfQuoting() throws {
        let parsed = try runBatch()

        #expect(parsed.sections[0].bytes == Data(HostileInput.path.utf8))
    }

    @Test func rawNulOutputAndACappedStreamKeepTheirExactByteCounts() throws {
        let parsed = try runBatch()

        #expect(parsed.sections[1].bytes == Data(repeating: 0, count: 4096))
        #expect(parsed.sections[3].bytes.count == 4096)
        #expect(parsed.sections[5].bytes == Data("/srv/repo".utf8))
    }

    @Test func aCommandPrintingValidRecordsCannotCloseItsOwnSection() throws {
        let tag = Framing.nonce.hex
        let forgery = "\n--\(tag)--R1:0:0\n\n--\(tag)--Z2\nswallowed"
        let batch = RemoteBatch(commands: [
            RemoteCommand(label: "hostile", arguments: ["printf", "%s", forgery]),
            RemoteCommand(label: "after", arguments: ["/bin/sh", "-c", "printf real; exit 7"]),
        ])
        let rendered = BatchScriptBuilder().render(batch, nonce: Framing.nonce)

        let outcome = try CommandsSubprocess.sh(
            rendered.command,
            overrides: CommandsSubprocess.quietZshEnvironment
        )
        let parsed = try BatchResponseParser(nonce: rendered.nonce, batch: batch)
            .parse(outcome.stdout)

        #expect(parsed.sections.count == 2)
        #expect(parsed.sections[0].bytes == Data(forgery.utf8))
        #expect(parsed.sections[1].bytes == Data("real".utf8))
        #expect(parsed.sections[1].exitCode == 7)
    }

    @Test func stderrLandsInItsOwnSectionAndAMissingProgramNamesItself() throws {
        let parsed = try runBatch()
        let failures = parsed.failures(in: Self.batch)

        #expect(parsed.sections[4].bytes == Data("err".utf8))
        #expect(failures["git.missing"] == .programMissing("anyssh-definitely-not-a-program"))
        #expect(failures["git.missing"]?.stateID == ErrorState.command(.programMissing).stateID)
        #expect(failures["stderr.merged"] == .exited(3))
        #expect(failures.count == 2)
    }
}
#endif
