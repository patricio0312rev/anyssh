import Testing

@testable import AnySSHCore

@Suite struct AgentKindPreferenceTests {
    private let detector = AgentKindDetector()

    @Test func aHelperDoesNotOutrankTheAgent() {
        let names = ["node", "codex-companion.mjs", "claude", "zsh"]

        #expect(detector.detect(processNames: names)?.id == "claude-code")
    }

    @Test func theOnlyAgentPresentWins() {
        #expect(detector.detect(processNames: ["zsh", "codex"])?.id == "codex")
    }

    @Test func aTreeWithNoAgentReportsNothing() {
        #expect(detector.detect(processNames: ["zsh", "node", "vim"]) == nil)
    }

    @Test func anAgentInsideAMultiplexerOutranksIt() {
        #expect(detector.detect(processNames: ["herdr", "claude"])?.id == "claude-code")
    }

    @Test func aMultiplexerAloneIsNotAnAgent() {
        #expect(detector.detect(processNames: ["herdr", "zsh"]) == nil)
        #expect(detector.detect(multiplexerTitle: "tmux") == nil)
    }

    @Test func aPaneTitleInsideTmuxIsAnAgent() {
        #expect(detector.detect(multiplexerTitle: "codex", terminalTitle: "tmux")?.id == "codex")
    }

    @Test func theFirstNonMultiplexerSignalWins() {
        #expect(
            detector.detect(signals: ["herdr", "nvim", "claude"])?.id == "claude-code"
        )
    }
}
