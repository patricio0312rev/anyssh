import AnySSHCore
import Foundation
import Testing

@testable import Multiplexers

@Suite struct HerdrAgentSnapshotTests {
    @Test func protocolTwentyTwoIsAccepted() async throws {
        let runner = ScriptedMuxRunner(sections: [
            HerdrCommands.detectLabel: try MuxFixtureData.bytes("herdr-status-protocol-22.json")
        ])
        let info = try await HerdrAdapter(runner: runner).detect()
        #expect(info.protocolVersion == 22)
        #expect(info.version == "0.9.3")
    }

    @Test func panesCarryTheAgentKindNameAndTerminalTitle() throws {
        let snapshot = try Self.snapshot()
        let byID = Dictionary(uniqueKeysWithValues: snapshot.panes.map { ($0.id.rawValue, $0) })

        #expect(byID["w1:p87"]?.agent == "claude")
        #expect(byID["w1:p87"]?.agentName == "agents-menu")
        #expect(byID["w1:p87"]?.terminalTitle == "api agents")
        #expect(byID["w1:p8A"]?.agent == "grok")
        #expect(byID["w1:p8A"]?.agentName == "compete")
        #expect(byID["w1:p4W"]?.agentName == nil)
        #expect(byID["w1:p90"]?.agent == nil)
        #expect(byID["w1:p90"]?.terminalTitle == "zsh")
    }

    @Test func everyAgentIsListedWithItsFullName() throws {
        let entries = MuxAgentDirectory.entries(in: try Self.snapshot())

        #expect(entries.map(\.id.rawValue) == ["w1:p4W", "w1:p6Q", "w1:p87", "w1:p8A"])
        #expect(entries.map(\.title) == ["release-notes", "deep search debug", "agents-menu", "compete"])
        #expect(
            entries.map(\.detail) == [
                nil,
                "Deep search across the payments service",
                "api agents",
                "- Thinking - Read briefs and execute described task - grok",
            ]
        )
        #expect(entries.map(\.tabTitle) == ["1", "7", "api agents", "api compete"])
        #expect(entries.map(\.kind?.id) == ["claude-code", "claude-code", "claude-code", "grok-code"])
        #expect(entries.map(\.status) == ["idle", "idle", "working", "working"])
        #expect(entries.filter(\.isActive).map(\.id.rawValue) == ["w1:p6Q"])
    }

    @Test func anAgentTargetsItsPaneInsideItsTab() throws {
        let entry = try #require(MuxAgentDirectory.entries(in: try Self.snapshot()).last)
        #expect(
            entry.target
                == MuxTarget(
                    session: MuxSessionID(rawValue: "default"),
                    group: MuxGroupID(rawValue: "w1:t8A"),
                    pane: MuxPaneID(rawValue: "w1:p8A")
                )
        )
    }

    private static func snapshot() throws -> MuxSnapshot {
        try HerdrParser().snapshot(
            from: MuxFixtureData.text("herdr-api-snapshot-agents.json"),
            session: MuxSession(id: MuxSessionID(rawValue: "default"), name: "default", isAttached: true)
        )
    }
}
