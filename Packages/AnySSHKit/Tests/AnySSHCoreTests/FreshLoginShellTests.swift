import Testing

@testable import AnySSHCore

@Suite struct FreshLoginShellTests {
    @Test func aLoneLoginShellUnderSshdIsAtThePrompt() {
        #expect(FreshLoginShell.isAtPrompt(processNames: ["sshd-session", "zsh"]))
        #expect(FreshLoginShell.isAtPrompt(processNames: ["sshd", "bash"]))
        #expect(FreshLoginShell.isAtPrompt(processNames: ["fish"]))
    }

    @Test func anyProgramBesideTheShellMeansTheForegroundIsUnknown() {
        #expect(!FreshLoginShell.isAtPrompt(processNames: ["sshd", "zsh", "vim"]))
        #expect(!FreshLoginShell.isAtPrompt(processNames: ["sshd", "zsh", "tmux"]))
        #expect(!FreshLoginShell.isAtPrompt(processNames: ["zsh", "gitstatusd"]))
    }

    @Test func noShellOrANestedShellIsNotAFreshPrompt() {
        #expect(!FreshLoginShell.isAtPrompt(processNames: []))
        #expect(!FreshLoginShell.isAtPrompt(processNames: ["sshd-session"]))
        #expect(!FreshLoginShell.isAtPrompt(processNames: ["sshd", "zsh", "bash"]))
    }
}
