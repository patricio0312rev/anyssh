import AnySSHCore
import Testing

@Suite struct MuxAgentDirectoryTests {
    @Test func aTmuxPaneTitledByAnAgentIsListed() {
        let entries = MuxAgentDirectory.entries(
            in: Self.snapshot(panes: [
                Self.pane("%1", title: "Claude Code"),
                Self.pane("%2", title: "build-box"),
            ])
        )
        #expect(entries.map(\.id.rawValue) == ["%1"])
        #expect(entries.first?.kind?.id == "claude-code")
        #expect(entries.first?.title == "Claude Code")
    }

    @Test func genericLabelsAndIdentifiersFallThroughToTheTerminalTitle() {
        let entries = MuxAgentDirectory.entries(
            in: Self.snapshot(panes: [
                Self.pane("w1:p6C", title: "agent", agent: "codex", terminalTitle: "w1:p6C"),
                Self.pane("w1:p6D", title: "shell", agent: "codex", terminalTitle: "Fix the login flow"),
            ])
        )
        #expect(entries.map(\.title) == ["Codex", "Fix the login flow"])
        #expect(entries.map(\.detail) == [nil, nil])
    }

    @Test func anUnknownHerdrAgentStillAppearsUnderItsOwnLabel() {
        let entries = MuxAgentDirectory.entries(
            in: Self.snapshot(panes: [Self.pane("w1:p1", title: "w1:p1", agent: "cursor")])
        )
        #expect(entries.map(\.title) == ["cursor"])
        #expect(entries.first?.kind == nil)
    }

    @Test func aTabNamedAfterItsIdentifierHasNoTabTitle() {
        let entries = MuxAgentDirectory.entries(
            in: Self.snapshot(panes: [Self.pane("w1:p1", title: "Ship it", agent: "pi")])
        )
        #expect(entries.first?.tabTitle == nil)
    }

    private static func snapshot(panes: [MuxPane]) -> MuxSnapshot {
        MuxSnapshot(
            session: MuxSession(id: MuxSessionID(rawValue: "main"), name: "main", isAttached: true),
            groups: [
                MuxGroup(
                    id: MuxGroupID(rawValue: "w1:t1"),
                    sessionID: MuxSessionID(rawValue: "main"),
                    title: "w1:t1",
                    isActive: true
                )
            ],
            panes: panes
        )
    }

    private static func pane(
        _ id: String,
        title: String,
        agent: String? = nil,
        terminalTitle: String? = nil
    ) -> MuxPane {
        MuxPane(
            id: MuxPaneID(rawValue: id),
            groupID: MuxGroupID(rawValue: "w1:t1"),
            title: title,
            workingDirectory: nil,
            isActive: false,
            agentStatus: nil,
            repositoryRoot: nil,
            agent: agent,
            terminalTitle: terminalTitle
        )
    }
}
