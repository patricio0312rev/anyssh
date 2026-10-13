import AnySSHCore
import AnySSHMocks
import Testing

@testable import AnySSHUI

@Suite @MainActor struct AgentsMenuModelTests {
    @Test func loadListsEveryAgentButNotTheShells() async throws {
        let model = JumpToModel(
            adapter: FixtureMultiplexerAdapter(fixture: .herdrDefault),
            directory: nil,
            writer: nil
        )
        await model.load()
        let agents = try #require(model.agentSessions.first?.agents)

        #expect(
            agents.map(\.title) == [
                "Refactor the billing webhooks",
                "login fix",
                "Write the release notes",
                "Audit the Terraform modules",
            ]
        )
        #expect(agents.map(\.detail) == [nil, "Fix the flaky login test", nil, nil])
        #expect(agents.map(\.kind?.id) == ["opencode", "claude-code", "codex", "gemini"])
        #expect(agents.map(\.tabTitle) == ["api", "web", "docs", "infra"])
    }

    @Test func tappingAnAgentFocusesItsPaneInsideItsTab() async throws {
        let adapter = FixtureMultiplexerAdapter(fixture: .herdrDefault)
        let model = JumpToModel(
            adapter: adapter,
            directory: nil,
            writer: MockRemoteConnection(),
            probe: { .attached(MuxSessionID(rawValue: "default")) }
        )
        await model.load()
        let agent = try #require(model.agentSessions.first?.agents.last)

        #expect(await model.jump(to: agent))
        #expect(model.lastOutcome == .focused)
        #expect(model.jumpingAgentID == nil)
        #expect(await adapter.focusLog.targets == [agent.target])
    }

    @Test func aFailedAgentJumpKeepsTheFailure() async throws {
        let model = JumpToModel(
            adapter: FixtureMultiplexerAdapter(fixture: .herdrDefault),
            directory: nil,
            writer: nil
        )
        await model.load()
        let agent = try #require(model.agentSessions.first?.agents.first)

        #expect(await model.jump(to: agent) == false)
        #expect(model.jumpFailure == .mux(.attachTargetVanished))
        #expect(!model.isJumping)
    }

    @Test func tmuxPanesWithoutAgentsLeaveTheMenuEmpty() async {
        let model = JumpToModel(
            adapter: FixtureMultiplexerAdapter(fixture: .tmuxMain),
            directory: nil,
            writer: nil
        )
        await model.load()
        #expect(model.agentSessions.isEmpty)
    }

    @Test func numberedTabsReadAsTabs() {
        let entry = MuxAgentEntry(
            id: MuxPaneID(rawValue: "w1:p1"),
            sessionID: MuxSessionID(rawValue: "default"),
            groupID: MuxGroupID(rawValue: "w1:t1"),
            title: "release-notes",
            detail: nil,
            tabTitle: "7",
            kind: nil,
            status: "idle",
            isActive: false
        )
        #expect(AgentsMenuCopy.location(of: entry) == "Tab 7")
    }
}
