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
        #expect(model.navbarTitle(mode: .agentSession) == model.activeRecord?.title)
    }

    @Test func anAgentSessionTitleWinsOverHerdr() throws {
        let model = SessionWorkspaceFixture.model("single")
        let sessionID = try #require(model.activeSessionID)
        model.replaceMultiplexer(
            for: sessionID,
            with: FixtureMultiplexerAdapter(fixture: .herdrDefault)
        )
        model.sessionAgentKinds[sessionID] = AgentKindCatalog.kinds.first { $0.id == "opencode" }
        model.rememberAgentSessionTitle("OC | Mejoras para v0.1.2", for: sessionID, replacing: true)
        #expect(model.navbarTitle(mode: .smart) == "OC | Mejoras para v0.1.2")
        #expect(model.navbarTitle(mode: .agentSession) == "OC | Mejoras para v0.1.2")
        #expect(model.navbarTitle(mode: .activeAgent) == "opencode")
        #expect(model.navbarTitle(mode: .multiplexer) == "herdr")
    }

    @Test func aGenericPaneLabelDoesNotReplaceAPublishedTitle() throws {
        let model = SessionWorkspaceFixture.model("single")
        let sessionID = try #require(model.activeSessionID)
        model.rememberAgentSessionTitle("OC | Mejoras para v0.1.2", for: sessionID, replacing: true)
        model.rememberAgentSessionTitle("agent", for: sessionID)
        #expect(model.navbarTitle(mode: .agentSession) == "OC | Mejoras para v0.1.2")
    }

    @Test func multiplexerFallsBackWhenNoAdapterIsAttached() {
        let model = SessionWorkspaceFixture.model("single")
        #expect(model.navbarTitle(mode: .multiplexer) == model.activeRecord?.title)
    }
}
