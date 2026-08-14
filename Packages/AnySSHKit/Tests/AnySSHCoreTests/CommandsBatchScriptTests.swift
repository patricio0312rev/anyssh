import Foundation
import Testing

@testable import AnySSHCore

@Suite struct BatchScriptTests {
    private static let batch = RemoteBatch(commands: [
        RemoteCommand(label: "repo.root", arguments: ["git", "rev-parse", "--show-toplevel"]),
        RemoteCommand(
            label: "git.diff",
            arguments: ["git", "diff", "--", HostileInput.path],
            byteCap: 262_144
        ),
    ])

    @Test func everyRequestGetsAFreshOneHundredAndTwentyEightBitNonce() {
        let nonces = (0..<64).map { _ in BatchScriptBuilder().render(Self.batch).nonce.hex }

        #expect(Set(nonces).count == 64)
        #expect(nonces.allSatisfy { $0.count == 32 })
        #expect(nonces.allSatisfy { $0.allSatisfy(\.isHexDigit) })
    }

    @Test func theWholeBatchTravelsAsOneLoginShellCommand() {
        let rendered = BatchScriptBuilder().render(Self.batch, nonce: Framing.nonce)

        #expect(rendered.command.hasPrefix("\"${SHELL:-/bin/sh}\" -lc '"))
        #expect(rendered.command.components(separatedBy: " -lc ").count == 2)
        #expect(rendered.command.hasSuffix("'"))
    }

    @Test func everyArgumentIsQuotedAndEveryCommandRedirectsItsOwnStderr() {
        let rendered = BatchScriptBuilder().render(Self.batch, nonce: Framing.nonce)
        let lines = rendered.script.split(separator: "\n", omittingEmptySubsequences: false)

        #expect(lines.first == "set -o pipefail 2>/dev/null || :")
        #expect(rendered.script.components(separatedBy: "2>&1").count == 3)
        #expect(lines.dropLast().last == #"\#(Self.quotedDiff) 2>&1 | 'head' -c 262144 >"$__f"; __r 1 $?"#)
        #expect(
            rendered.script.contains(
                #"'git' 'rev-parse' '--show-toplevel' >"$__f" 2>&1; __r 0 $?"#
            )
        )
    }

    @Test func everySectionIsMeasuredOnDiskAndPrintedAheadOfItsBytes() {
        let rendered = BatchScriptBuilder().render(Self.batch, nonce: Framing.nonce)

        #expect(rendered.script.contains(#"__f="$__d/section""#))
        #expect(rendered.script.contains(#"$('wc' -c <"$__f")"#))
        #expect(rendered.script.contains(#"printf '\n--%s--R%s:%s:%s\n' "$__n" "$1""#))
        #expect(rendered.script.contains(#"'cat' "$__f""#))
    }

    @Test func theTemporaryDirectoryIsMadeSafelyAndAlwaysRemoved() {
        let rendered = BatchScriptBuilder().render(Self.batch, nonce: Framing.nonce)

        #expect(rendered.script.contains(#"__d=$('mktemp' -d) || exit 1"#))
        #expect(rendered.script.contains(#"trap 'rm -rf "$__d"' EXIT INT HUP TERM"#))
    }

    @Test func theScriptAndTheParserAgreeOnTheDelimiterAndTheClosingRecord() {
        let rendered = BatchScriptBuilder().render(Self.batch, nonce: Framing.nonce)

        #expect(rendered.script.contains("__n='\(Framing.nonce.hex)'"))
        #expect(rendered.nonce.delimiter == Data("\n--\(Framing.nonce.hex)--".utf8))
        #expect(rendered.script.hasSuffix("\n__z 2"))
    }

    @Test func anEmptyBatchRendersThePreambleAndTheClosingRecord() {
        let rendered = BatchScriptBuilder().render(RemoteBatch(commands: []), nonce: Framing.nonce)

        #expect(rendered.script.split(separator: "\n").count == 8)
        #expect(!rendered.script.contains("__r "))
        #expect(rendered.script.hasSuffix("\n__z 0"))
    }

    private static let quotedDiff = "'git' 'diff' '--' \(ShellQuoting.singleQuote(HostileInput.path))"
}
