import AnySSHCore
import AnySSHMocks
import Foundation
import Sessions
import Testing

@testable import AnySSHUI

@Suite @MainActor struct SessionNavbarTitleWorkspaceTests {
    @Test func sessionNameUsesTheRecordTitle() {
        let model = SessionWorkspaceFixture.model("single")
        #expect(model.navbarTitle(mode: .sessionName) == model.activeRecord?.title)
    }

    @Test func activeAgentFallsBackWhenNothingIsDetected() {
        let model = SessionWorkspaceFixture.model("single")
        #expect(model.navbarTitle(mode: .activeAgent) == model.activeRecord?.title)
    }

    @Test func smartTitleJoinsAnAgentInsideHerdr() throws {
        let model = SessionWorkspaceFixture.model("single")
        let sessionID = try #require(model.activeSessionID)
        model.replaceMultiplexer(
            for: sessionID,
            with: FixtureMultiplexerAdapter(fixture: .herdrDefault)
        )
        model.sessionAgentKinds[sessionID] = AgentKindCatalog.kinds.first { $0.id == "codex" }
        #expect(model.navbarTitle(mode: .smart) == "Codex • herdr")
        #expect(model.navbarTitle(mode: .activeAgent) == "Codex")
        #expect(model.navbarTitle(mode: .multiplexer) == "herdr")
    }

    @Test func multiplexerFallsBackWhenNoAdapterIsAttached() {
        let model = SessionWorkspaceFixture.model("single")
        #expect(model.navbarTitle(mode: .multiplexer) == model.activeRecord?.title)
    }
}
