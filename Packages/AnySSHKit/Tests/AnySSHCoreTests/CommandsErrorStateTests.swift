import Foundation
import Testing

@testable import AnySSHCore

@Suite struct CommandErrorStateTests {
    private static let failures: [CommandFailure] = [
        .programMissing("git"),
        .programMissing("anyssh-definitely-not-a-program"),
        .programMissing(""),
        .signalled(13),
        .signalled(9),
        .exited(1),
        .exited(255),
    ]

    private static let framing: [BatchFramingError] = [
        .missingSection(label: "git.log"),
        .unterminatedSection(label: "git.log"),
        .desynchronised(label: "git.log"),
        .trailingBytes(label: "git.log"),
        .responseTooLarge(label: "git.log", limit: 4096),
    ]

    @Test func everyIdentifierACommandFailureProducesResolvesInTheRegistry() {
        for failure in Self.failures {
            #expect(ErrorState(stateID: failure.stateID) != nil, "unregistered: \(failure.stateID)")
        }
    }

    @Test func everyIdentifierAFramingErrorProducesResolvesInTheRegistry() {
        for error in Self.framing {
            #expect(ErrorState(stateID: error.stateID) != nil, "unregistered: \(error.stateID)")
        }
    }

    @Test func theExitCodeAndTheSignalNumberStayOnTheFailure() {
        #expect(CommandFailure.exited(3) != .exited(4))
        #expect(CommandFailure.signalled(13) != .signalled(9))
        #expect(CommandFailure.programMissing("git") != .programMissing("tmux"))
        #expect(CommandFailure.exited(3).stateID == CommandFailure.exited(4).stateID)
    }

    @Test func aMissingGitReachesGitsOwnStateAndEverythingElseTheGenericOne() {
        #expect(CommandFailure.programMissing("git").stateID == ErrorState.git(.missing).stateID)
        #expect(
            CommandFailure.programMissing("tmux").stateID
                == ErrorState.command(.programMissing).stateID
        )
    }

    @Test func theIdentifiersTheLayerProducesFitTheRegistrysGrammar() {
        let pattern = /^[a-z]+\.[a-z][a-zA-Z]+$/
        let produced = Self.failures.map(\.stateID) + Self.framing.map(\.stateID)

        #expect(produced.allSatisfy { $0.wholeMatch(of: pattern) != nil })
        #expect("command.exit.1".wholeMatch(of: pattern) == nil)
        #expect("anyssh-definitely-not-a-program.missing".wholeMatch(of: pattern) == nil)
    }
}
