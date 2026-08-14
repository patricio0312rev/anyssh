import AnySSHCore

enum FixtureMultiplexerTrees {
    struct Built: Sendable {
        var info: MultiplexerInfo
        var sessions: [MuxSession]
        var snapshots: [MuxSessionID: MuxSnapshot]
        var bindings: MuxKeyBindings
        var paneText: String
    }
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
            workingDirectory: "/Users/dev/src/anyssh",
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
        let session = MuxSession(
            id: MuxSessionID(rawValue: "default"),
            name: "default",
            isAttached: true
        )
        let group = MuxGroup(
            id: MuxGroupID(rawValue: "w1:t1"),
            sessionID: session.id,
            title: "main",
            isActive: true
        )
        let pane = MuxPane(
            id: MuxPaneID(rawValue: "w1:p1"),
            groupID: group.id,
            title: "opencode",
            workingDirectory: "/Users/dev/src/anyssh/Packages",
            isActive: true,
            agentStatus: "working",
            repositoryRoot: "/Users/dev/src/anyssh"
        )
        let idlePane = MuxPane(
            id: MuxPaneID(rawValue: "w1:p2"),
            groupID: group.id,
            title: "shell",
            workingDirectory: "/Users/dev/src/my project's \"notes\"",
            isActive: false,
            agentStatus: "idle",
            repositoryRoot: nil
        )
        return FixtureMultiplexerTrees.Built(
            info: MultiplexerInfo(
                kind: .herdr,
                binaryPath: "/Users/dev/.local/bin/herdr",
                version: "0.8.0",
                protocolVersion: 19
            ),
            sessions: [session],
            snapshots: [session.id: MuxSnapshot(session: session, groups: [group], panes: [pane, idlePane])],
            bindings: MuxKeyBindings(prefix: "ctrl+b", chords: ["new_tab": "prefix+t"]),
            paneText: "herdr fixture pane"
        )
    }
}
