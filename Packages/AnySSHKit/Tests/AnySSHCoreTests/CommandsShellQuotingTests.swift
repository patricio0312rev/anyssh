import Foundation
import Testing

@testable import AnySSHCore

@Suite struct ShellQuotingTests {
    @Test func embeddedQuotesCloseEscapeAndReopen() {
        #expect(ShellQuoting.singleQuote("it's") == #"'it'\''s'"#)
        #expect(ShellQuoting.singleQuote("") == "''")
        #expect(ShellQuoting.singleQuote("'") == #"''\'''"#)
    }

    #if os(macOS)
    @Test(arguments: HostileInput.corpus)
    func quotedValueIsInertUnderOneShell(_ value: String) throws {
        let echoed = try CommandsSubprocess.sh("printf '%s' \(ShellQuoting.singleQuote(value))")

        #expect(echoed.stdout == Data(value.utf8))
        #expect(echoed.exitCode == 0)

        let counted = try CommandsSubprocess.sh(
            "set -- \(ShellQuoting.singleQuote(value)); printf '%s' \"$#\""
        )
        #expect(String(decoding: counted.stdout, as: UTF8.self) == "1")
    }

    @Test(arguments: HostileInput.corpus)
    func quotedValueSurvivesTheLoginShellWrapper(_ value: String) throws {
        let script = "printf '%s' \(ShellQuoting.singleQuote(value))"
        let echoed = try CommandsSubprocess.sh(
            LoginShellWrapper.wrap(script),
            overrides: CommandsSubprocess.quietZshEnvironment
        )

        #expect(echoed.stdout == Data(value.utf8))
        #expect(echoed.exitCode == 0)
    }

    @Test func theWrapperStillRunsWhenTheHostHasNoSHELL() throws {
        let script = "printf '%s' \(ShellQuoting.singleQuote(HostileInput.path))"
        let echoed = try CommandsSubprocess.sh(LoginShellWrapper.wrap(script), removing: ["SHELL"])

        #expect(echoed.stdout == Data(HostileInput.path.utf8))
        #expect(echoed.exitCode == 0)
    }

    @Test func quotingIsClosedUnderRepetition() throws {
        let once = ShellQuoting.singleQuote(HostileInput.path)
        let twice = ShellQuoting.singleQuote(once)
        let echoed = try CommandsSubprocess.sh("printf '%s' \(twice)")

        #expect(String(decoding: echoed.stdout, as: UTF8.self) == once)
    }

    @Test func unicodeIsNeitherNormalisedNorFolded() throws {
        let composed = try CommandsSubprocess.sh(
            "printf '%s' \(ShellQuoting.singleQuote(HostileInput.composed))"
        )
        let decomposed = try CommandsSubprocess.sh(
            "printf '%s' \(ShellQuoting.singleQuote(HostileInput.decomposed))"
        )

        #expect(composed.stdout == Data(HostileInput.composed.utf8))
        #expect(decomposed.stdout == Data(HostileInput.decomposed.utf8))
        #expect(composed.stdout != decomposed.stdout)
    }

    @Test func commandSubstitutionNeverRuns() throws {
        let marker = FileManager.default.temporaryDirectory.appending(path: "anyssh-quoting-breach")
        try? FileManager.default.removeItem(at: marker)
        let payload = "x$(touch \(marker.path(percentEncoded: false)))`touch \(marker.path())`"

        let echoed = try CommandsSubprocess.sh(
            LoginShellWrapper.wrap("printf '%s' \(ShellQuoting.singleQuote(payload))"),
            overrides: CommandsSubprocess.quietZshEnvironment
        )

        #expect(echoed.stdout == Data(payload.utf8))
        #expect(!FileManager.default.fileExists(atPath: marker.path(percentEncoded: false)))
    }
    #endif
}
