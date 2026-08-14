import Foundation
import Testing

@testable import AnySSHCore

@Suite struct CommandExitCodeTests {
    private static let batch = RemoteBatch(commands: [
        RemoteCommand(label: "git.diff", arguments: ["git", "diff"], byteCap: 262_144),
        RemoteCommand(label: "git.status", arguments: ["git", "status"]),
        RemoteCommand(label: "repo.root", arguments: ["/opt/homebrew/bin/git", "rev-parse"]),
    ])

    private func parse(_ exits: [Int32], bodies: [Data]) throws -> BatchResponse {
        let response = Framing.response(Array(zip(bodies, exits)))
        return try BatchResponseParser(nonce: Framing.nonce, batch: Self.batch).parse(response)
    }

    @Test func aCappedSectionExitingOn141IsTruncatedNotFailed() throws {
        let capped = Data(repeating: 0x41, count: 262_144)
        let parsed = try parse([141, 0, 0], bodies: [capped, Data(), Data()])
        let section = parsed.sections[0]

        #expect(section.truncated)
        #expect(!section.failed)
        #expect(section.exitCode == 141)
        #expect(section.failure(program: "git") == nil)
        #expect(parsed.failures(in: Self.batch).isEmpty)
    }

    @Test func anUncappedSectionExitingOn141IsAFailure() throws {
        let parsed = try parse([0, 141, 0], bodies: [Data(), Data(), Data()])
        let section = parsed.sections[1]

        #expect(!section.truncated)
        #expect(section.failed)
        #expect(section.failure(program: "git") == .signalled(13))
        #expect(section.failure(program: "git")?.stateID == ErrorState.command(.signalled).stateID)
    }

    @Test func exit127IsReportedAsGitMissing() throws {
        let message = Framing.bytes("zsh:1: command not found: git\n")
        let parsed = try parse([0, 127, 0], bodies: [Data(), message, Data()])
        let section = parsed.sections[1]

        #expect(section.failed)
        #expect(section.failure(program: "git") == .programMissing("git"))
        #expect(parsed.failures(in: Self.batch)["git.status"]?.stateID == "git.missing")
        #expect(section.bytes == message)
    }

    @Test func theMissingProgramStateIsTheRegisteredOne() throws {
        let parsed = try parse([0, 127, 0], bodies: [Data(), Data(), Data()])

        #expect(parsed.sections[1].failure(program: "git")?.stateID == ErrorState.git(.missing).stateID)
    }

    @Test func anAbsolutePathStillReportsAsGitMissing() throws {
        let parsed = try parse([0, 0, 127], bodies: [Data(), Data(), Data()])

        #expect(parsed.failures(in: Self.batch)["repo.root"]?.stateID == "git.missing")
    }

    @Test func anOrdinaryNonZeroExitKeepsItsCode() throws {
        let parsed = try parse([0, 1, 0], bodies: [Data(), Data(), Data()])

        #expect(parsed.sections[1].failure(program: "git") == .exited(1))
        #expect(
            parsed.failures(in: Self.batch)["git.status"]?.stateID
                == ErrorState.command(.failed).stateID)
    }

    @Test func fillingTheCapExactlyCountsAsTruncation() throws {
        let capped = Data(repeating: 0x41, count: 262_144)
        let parsed = try parse([0, 0, 0], bodies: [capped, Data(), Data()])

        #expect(parsed.sections[0].truncated)
        #expect(!parsed.sections[0].failed)
    }
}
