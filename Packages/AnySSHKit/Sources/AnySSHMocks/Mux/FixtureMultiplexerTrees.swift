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

    static func tree(for fixture: MuxFixture) -> FixtureMultiplexerTrees.Built {
        switch fixture {
        case .tmuxMain: tmuxFixture()
        case .tmuxCluster: tmuxClusterFixture()
        case .herdrCluster: herdrClusterFixture()
        case .herdrDefault, .herdrProtocolMismatch, .absent: herdrFixture()
        }
    }

    static func tmuxClusterFixture() -> FixtureMultiplexerTrees.Built {
        cluster(
            around: tmuxFixture(),
            adding: [
                detached(id: "$2", name: "api", repository: "api"),
                detached(id: "$3", name: "infra", repository: "infra"),
            ]
        )
    }

    static func herdrClusterFixture() -> FixtureMultiplexerTrees.Built {
        cluster(
            around: herdrFixture(),
            adding: [
                detached(id: "review", name: "review", repository: "web"),
                detached(id: "ops", name: "ops", repository: "infra"),
            ]
        )
    }

    private struct DetachedSession {
        var session: MuxSession
        var snapshot: MuxSnapshot
    }

    private static func cluster(
        around base: FixtureMultiplexerTrees.Built,
        adding extras: [DetachedSession]
    ) -> FixtureMultiplexerTrees.Built {
        var built = base
        built.sessions += extras.map(\.session)
        for extra in extras {
            built.snapshots[extra.session.id] = extra.snapshot
        }
        return built
    }

    private static func detached(
        id: String,
        name: String,
        repository: String
    ) -> DetachedSession {
        let session = MuxSession(id: MuxSessionID(rawValue: id), name: name, isAttached: false)
        let group = MuxGroup(
            id: MuxGroupID(rawValue: "\(id):@1"),
            sessionID: session.id,
            title: repository,
            isActive: true
        )
        let pane = MuxPane(
            id: MuxPaneID(rawValue: "\(id):%1"),
            groupID: group.id,
            title: "shell",
            workingDirectory: "\(FixtureMultiplexerTrees.source)/\(repository)",
            isActive: true,
            agentStatus: nil,
            repositoryRoot: "\(FixtureMultiplexerTrees.source)/\(repository)"
        )
        return DetachedSession(
            session: session,
            snapshot: MuxSnapshot(session: session, groups: [group], panes: [pane])
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
