import AnySSHCore

enum FixtureMultiplexerTrees {
    struct Built: Sendable {
        var info: MultiplexerInfo
        var sessions: [MuxSession]
        var snapshots: [MuxSessionID: MuxSnapshot]
        var bindings: MuxKeyBindings
        var paneText: String
    }

    static let home = "/home/dev"
    static let source = "/home/dev/src"
}

extension FixtureMultiplexerAdapter {
    static func tmuxFixture() -> FixtureMultiplexerTrees.Built {
        let session = MuxSession(
            id: MuxSessionID(rawValue: "$1"),
            name: "main",
            isAttached: true
        )
        let group = MuxGroup(
            id: MuxGroupID(rawValue: "@1"),
            sessionID: session.id,
            title: "code",
            isActive: true
        )
        let pane = MuxPane(
            id: MuxPaneID(rawValue: "%1"),
            groupID: group.id,
            title: "nvim",
            workingDirectory: "\(FixtureMultiplexerTrees.source)/api",
            isActive: true,
            agentStatus: nil,
            repositoryRoot: nil
        )
        return FixtureMultiplexerTrees.Built(
            info: MultiplexerInfo(
                kind: .tmux,
                binaryPath: "/opt/homebrew/bin/tmux",
                version: "3.6a",
                protocolVersion: nil
            ),
            sessions: [session],
            snapshots: [session.id: MuxSnapshot(session: session, groups: [group], panes: [pane])],
            bindings: MuxKeyBindings(prefix: "C-b", chords: [:]),
            paneText: "fixture pane"
        )
    }

    static func herdrFixture() -> FixtureMultiplexerTrees.Built {
        let session = MuxSession(id: MuxSessionID(rawValue: "default"), name: "default", isAttached: true)
        let tabs = herdrTabs(in: session.id)
        let panes = tabs.flatMap(\.panes)
        return FixtureMultiplexerTrees.Built(
            info: MultiplexerInfo(
                kind: .herdr,
                binaryPath: "\(FixtureMultiplexerTrees.home)/.local/bin/herdr",
                version: "0.8.0",
                protocolVersion: 19
            ),
            sessions: [session],
            snapshots: [
                session.id: MuxSnapshot(session: session, groups: tabs.map(\.group), panes: panes)
            ],
            bindings: MuxKeyBindings(prefix: "ctrl+b", chords: ["new_tab": "prefix+t"]),
            paneText: "herdr fixture pane"
        )
    }

    private struct HerdrTab {
        var group: MuxGroup
        var panes: [MuxPane]
    }

    private static func herdrTabs(in session: MuxSessionID) -> [HerdrTab] {
        [
            tab(
                session: session,
                index: 1,
                repo: "api",
                isActive: true,
                agents: [("opencode", "working"), ("shell", "idle")]
            ),
            tab(
                session: session,
                index: 2,
                repo: "web",
                isActive: false,
                agents: [("claude", "blocked")]
            ),
            tab(
                session: session,
                index: 3,
                repo: "docs",
                isActive: false,
                agents: [("codex", "done")]
            ),
            tab(
                session: session,
                index: 4,
                repo: "infra",
                isActive: false,
                agents: [("gemini", "idle"), ("shell", "idle")]
            ),
        ]
    }

    private static func tab(
        session: MuxSessionID,
        index: Int,
        repo: String,
        isActive: Bool,
        agents: [(String, String)]
    ) -> HerdrTab {
        let group = MuxGroup(
            id: MuxGroupID(rawValue: "w1:t\(index)"),
            sessionID: session,
            title: repo,
            isActive: isActive
        )
        let root = "\(FixtureMultiplexerTrees.source)/\(repo)"
        let panes = agents.enumerated().map { position, agent in
            MuxPane(
                id: MuxPaneID(rawValue: "w\(index):p\(position + 1)"),
                groupID: group.id,
                title: agent.0,
                workingDirectory: position == 0 ? root : "\(root)/tests",
                isActive: position == 0,
                agentStatus: agent.1,
                repositoryRoot: root
            )
        }
        return HerdrTab(group: group, panes: panes)
    }
}
