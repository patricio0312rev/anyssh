import Testing

@testable import AnySSHCore

@Suite struct SessionNavbarTitleTests {
    @Test func sessionNameUsesTheRecordTitle() {
        #expect(SessionNavbarTitle.resolve(.sessionName, context: Self.full) == "build-box")
    }

    @Test func agentSessionUsesThePublishedTitle() {
        #expect(
            SessionNavbarTitle.resolve(.agentSession, context: Self.full)
                == "OC | Mejoras para v0.1.2"
        )
    }

    @Test func activeAgentUsesTheDetectedAgent() {
        #expect(SessionNavbarTitle.resolve(.activeAgent, context: Self.full) == "OpenCode")
    }

    @Test func multiplexerUsesTheAttachedMux() {
        #expect(SessionNavbarTitle.resolve(.multiplexer, context: Self.full) == "herdr")
    }

    @Test func smartTitlePrefersThePublishedAgentSession() {
        #expect(
            SessionNavbarTitle.resolve(.smart, context: Self.full) == "OC | Mejoras para v0.1.2"
        )
    }

    @Test func missingSignalsFallBackToTheSessionName() {
        let empty = SessionTitleContext(sessionName: "build-box")
        #expect(SessionNavbarTitle.resolve(.agentSession, context: empty) == "build-box")
        #expect(SessionNavbarTitle.resolve(.activeAgent, context: empty) == "build-box")
        #expect(SessionNavbarTitle.resolve(.multiplexer, context: empty) == "build-box")
        #expect(SessionNavbarTitle.resolve(.smart, context: empty) == "build-box")
    }

    @Test func smartTitleJoinsAnAgentWhenNoSessionTitleExists() {
        let named = SessionTitleContext(
            sessionName: "build-box",
            agentName: "Codex",
            multiplexerName: "herdr"
        )
        #expect(SessionNavbarTitle.resolve(.smart, context: named) == "Codex • herdr")
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
        #expect(SessionNavbarTitle.preview(for: .agentSession) == "OC | Mejoras para v0.1.2")
        #expect(SessionNavbarTitle.preview(for: .activeAgent) == "OpenCode")
        #expect(SessionNavbarTitle.preview(for: .multiplexer) == "herdr")
        #expect(SessionNavbarTitle.preview(for: .smart) == "OC | Mejoras para v0.1.2")
    }

    @Test func genericPaneLabelsAreNotAgentSessionTitles() {
        #expect(!SessionNavbarTitle.isUsableAgentSessionTitle("agent"))
        #expect(!SessionNavbarTitle.isUsableAgentSessionTitle("nvim"))
        #expect(SessionNavbarTitle.isUsableAgentSessionTitle("OC | Mejoras para v0.1.2"))
    }

    private static let full = SessionTitleContext(
        sessionName: "build-box",
        agentSessionTitle: "OC | Mejoras para v0.1.2",
        agentName: "OpenCode",
        multiplexerName: "herdr"
    )
}
