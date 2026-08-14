import AnySSHCore
import Foundation
import Testing

@testable import Multiplexers

@Suite struct TmuxAdapterTests {
    @Test func parsesRecordedTopologyNodeByNodeIncludingQuotedPath() throws {
        let parser = TmuxParser()
        let sessionsText = try MuxFixtureData.text("tmux-list-sessions.txt")
        let windowsText = try MuxFixtureData.text("tmux-list-windows.txt")
        let panesText = try MuxFixtureData.text("tmux-list-panes.txt")
        let prefixText = try MuxFixtureData.text("tmux-prefix.txt")

        let sessions = try parser.sessions(from: sessionsText)
        #expect(sessions.count == 2)
        #expect(sessions[0] == MuxSession(id: MuxSessionID(rawValue: "$1"), name: "main", isAttached: true))
        #expect(
            sessions[1] == MuxSession(id: MuxSessionID(rawValue: "$2"), name: "agents", isAttached: false))

        let snapshot = try parser.snapshot(
            sessionID: MuxSessionID(rawValue: "$1"),
            sessionsText: sessionsText,
            windowsText: windowsText,
            panesText: panesText
        )
        #expect(snapshot.session.name == "main")
        #expect(
            snapshot.groups == [
                MuxGroup(
                    id: MuxGroupID(rawValue: "@1"),
                    sessionID: MuxSessionID(rawValue: "$1"),
                    title: "code",
                    isActive: true
                ),
                MuxGroup(
                    id: MuxGroupID(rawValue: "@2"),
                    sessionID: MuxSessionID(rawValue: "$1"),
                    title: "shell",
                    isActive: false
                ),
            ])
        #expect(snapshot.panes.count == 3)
        #expect(snapshot.panes[0].workingDirectory == "/Users/dev/src/anyssh")
        #expect(snapshot.panes[1].workingDirectory == #"/Users/dev/src/my project's "notes""#)
        #expect(snapshot.panes[1].id.rawValue == "%2")
        #expect(snapshot.panes[2].groupID.rawValue == "@2")
        #expect(parser.prefix(from: prefixText) == "C-b")
    }

    @Test func adapterDetectListSnapshotBindingsAndAttachUseRunner() async throws {
        let runner = ScriptedMuxRunner(sections: [
            TmuxCommands.detectLabel: try MuxFixtureData.bytes("tmux-version.txt"),
            TmuxCommands.sessionsLabel: try MuxFixtureData.bytes("tmux-list-sessions.txt"),
            TmuxCommands.windowsLabel: try MuxFixtureData.bytes("tmux-list-windows.txt"),
            TmuxCommands.panesLabel: try MuxFixtureData.bytes("tmux-list-panes.txt"),
            TmuxCommands.prefixLabel: try MuxFixtureData.bytes("tmux-prefix.txt"),
            TmuxCommands.captureLabel: Data("pane body\n".utf8),
        ])
        let adapter = TmuxAdapter(runner: runner, binaryPath: "/opt/homebrew/bin/tmux")

        let info = try await adapter.detect()
        #expect(info.kind == .tmux)
        #expect(info.version == "3.6a")
        #expect(info.binaryPath == "/opt/homebrew/bin/tmux")

        let sessions = try await adapter.listSessions()
        #expect(sessions.map(\.name) == ["main", "agents"])

        let snapshot = try await adapter.snapshot(MuxSessionID(rawValue: "$1"))
        #expect(snapshot.panes[1].workingDirectory == #"/Users/dev/src/my project's "notes""#)

        let bindings = try await adapter.keyBindings()
        #expect(bindings.prefix == "C-b")

        let text = try await adapter.readPane(MuxPaneID(rawValue: "%1"), lines: 20)
        #expect(text.contains("pane body"))

        let attach = adapter.attachCommand(
            MuxTarget(
                session: MuxSessionID(rawValue: "main"),
                group: MuxGroupID(rawValue: "@1"),
                pane: MuxPaneID(rawValue: "%1")
            )
        )
        #expect(
            attach
                == "'/opt/homebrew/bin/tmux' attach-session -t 'main' \\; select-pane -t '%1'"
        )
        #expect(adapter.capabilities == .tmux)
        #expect(adapter.capabilities.localSessionSurvival == .proven)
    }
}
