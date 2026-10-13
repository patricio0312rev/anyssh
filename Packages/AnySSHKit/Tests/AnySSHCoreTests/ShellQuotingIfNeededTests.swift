import Testing

@testable import AnySSHCore

@Suite struct ShellQuotingIfNeededTests {
    @Test func leavesAPlainPathBare() {
        let path = "/home/me/.cache/anyssh/paste/paste-20251013-140233-500.png"

        #expect(ShellQuoting.quotedIfNeeded(path) == path)
    }

    @Test(arguments: [
        "/home/my user/shot.png",
        "/tmp/it's.png",
        "/tmp/$HOME.png",
        "/tmp/a;rm -rf.png",
        "/tmp/`id`.png",
        "/tmp/glob*.png",
    ])
    func quotesAnythingAShellWouldReadIntoIt(_ path: String) {
        #expect(ShellQuoting.quotedIfNeeded(path) == ShellQuoting.singleQuote(path))
    }

    @Test func quotesTheEmptyString() {
        #expect(ShellQuoting.quotedIfNeeded("") == "''")
    }
}
