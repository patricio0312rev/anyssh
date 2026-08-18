import Testing

@testable import AnySSHCore

@Suite struct SessionNavbarTitleTests {
    @Test func sessionNameUsesTheRecordTitle() {
        #expect(SessionNavbarTitle.resolve(.sessionName, context: Self.full) == "build-box")
    }

    @Test func activeAgentUsesTheDetectedAgent() {
        #expect(SessionNavbarTitle.resolve(.activeAgent, context: Self.full) == "Codex")
    }

    @Test func multiplexerUsesTheAttachedMux() {
        #expect(SessionNavbarTitle.resolve(.multiplexer, context: Self.full) == "herdr")
    }

    @Test func smartTitleJoinsAnAgentInsideAMultiplexer() {
        #expect(SessionNavbarTitle.resolve(.smart, context: Self.full) == "Codex • herdr")
    }

    @Test func missingSignalsFallBackToTheSessionName() {
        let empty = SessionTitleContext(sessionName: "build-box")
        #expect(SessionNavbarTitle.resolve(.activeAgent, context: empty) == "build-box")
        #expect(SessionNavbarTitle.resolve(.multiplexer, context: empty) == "build-box")
        #expect(SessionNavbarTitle.resolve(.smart, context: empty) == "build-box")
    }

    @Test func smartTitleDoesNotRepeatTheSameName() {
        let herdrOnly = SessionTitleContext(
            sessionName: "build-box",
            agentName: "herdr",
            multiplexerName: "herdr"
        )
        #expect(SessionNavbarTitle.resolve(.smart, context: herdrOnly) == "herdr")
    }

    @Test func previewsMatchTheSampleContext() {
        #expect(SessionNavbarTitle.preview(for: .sessionName) == "build-box")
        #expect(SessionNavbarTitle.preview(for: .activeAgent) == "Codex")
        #expect(SessionNavbarTitle.preview(for: .multiplexer) == "herdr")
        #expect(SessionNavbarTitle.preview(for: .smart) == "Codex • herdr")
    }

    private static let full = SessionTitleContext(
        sessionName: "build-box",
        agentName: "Codex",
        multiplexerName: "herdr"
    )
}
