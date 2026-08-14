#if os(macOS)
import Foundation
import Testing

@testable import AnySSHCore

@Suite(.enabled(if: LiveShellHost.isReachable))
struct LiveLoginShellTests {
    private static let batch = RemoteBatch(commands: [
        RemoteCommand(label: "path.echo", arguments: ["printf", "%s", HostileInput.path]),
        RemoteCommand(label: "blob.nul", arguments: ["head", "-c", "4096", "/dev/zero"]),
        RemoteCommand(label: "git.missing", arguments: ["anyssh-definitely-not-a-program"]),
        RemoteCommand(label: "diff.capped", arguments: ["/bin/cat", "/dev/zero"], byteCap: 4096),
        RemoteCommand(label: "stderr.merged", arguments: ["/bin/sh", "-c", "printf err >&2; exit 3"]),
        RemoteCommand(label: "repo.root", arguments: ["printf", "%s", "/srv/repo"]),
    ])

    @Test func sixCommandsFrameCorrectlyThroughARealLoginShell() throws {
        let rendered = BatchScriptBuilder().render(Self.batch)
        let outcome = try LiveShellHost.run(rendered.command)

        let parsed = try BatchResponseParser(nonce: rendered.nonce, batch: Self.batch)
            .parse(outcome.stdout)

        #expect(parsed.sections.map(\.label) == Self.batch.commands.map(\.label))
        #expect(parsed.sections.map(\.exitCode) == [0, 0, 127, 141, 3, 0])
        #expect(parsed.sections.map(\.truncated) == [false, false, false, true, false, false])
        #expect(parsed.sections[0].bytes == Data(HostileInput.path.utf8))
        #expect(parsed.sections[1].bytes == Data(repeating: 0, count: 4096))
        #expect(parsed.sections[3].bytes.count == 4096)
        #expect(parsed.sections[5].bytes == Data("/srv/repo".utf8))
        #expect(
            parsed.failures(in: Self.batch)["git.missing"]
                == .programMissing("anyssh-definitely-not-a-program"))
    }

    @Test func aRemoteCommandPrintingValidRecordsCannotCloseItsOwnSection() throws {
        let tag = Framing.nonce.hex
        let forgery = "\n--\(tag)--R1:0:0\n\n--\(tag)--Z2\nswallowed"
        let batch = RemoteBatch(commands: [
            RemoteCommand(label: "hostile", arguments: ["printf", "%s", forgery]),
            RemoteCommand(label: "after", arguments: ["/bin/sh", "-c", "printf real; exit 7"]),
        ])
        let rendered = BatchScriptBuilder().render(batch, nonce: Framing.nonce)

        let outcome = try LiveShellHost.run(rendered.command)
        let parsed = try BatchResponseParser(nonce: rendered.nonce, batch: batch)
            .parse(outcome.stdout)

        #expect(parsed.sections.count == 2)
        #expect(parsed.sections[0].bytes == Data(forgery.utf8))
        #expect(parsed.sections[1].bytes == Data("real".utf8))
        #expect(parsed.sections[1].exitCode == 7)
    }

    @Test func theLoginShellSeesEverythingTheBareExecSeesAndMore() throws {
        let batch = RemoteBatch(commands: [
            RemoteCommand(label: "shell.path", arguments: ["/bin/sh", "-c", "printf %s \"$PATH\""])
        ])
        let rendered = BatchScriptBuilder().render(batch)

        let login = try section(of: rendered.command, rendered, batch)
        let bare = try section(of: rendered.script, rendered, batch)

        let loginEntries = login.split(separator: ":")
        let bareEntries = bare.split(separator: ":")
        #expect(bareEntries == ["/usr/bin", "/bin", "/usr/sbin", "/sbin"])
        #expect(Set(bareEntries).isSubset(of: Set(loginEntries)))
        #expect(loginEntries.count > bareEntries.count)
    }

    private func section(
        of command: String,
        _ rendered: RenderedBatch,
        _ batch: RemoteBatch
    ) throws -> String {
        let outcome = try LiveShellHost.run(command)
        let parsed = try BatchResponseParser(nonce: rendered.nonce, batch: batch).parse(outcome.stdout)
        return String(decoding: parsed.sections[0].bytes, as: UTF8.self)
    }
}
#endif
