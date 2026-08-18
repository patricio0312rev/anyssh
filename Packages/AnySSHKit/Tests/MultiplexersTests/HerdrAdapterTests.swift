import AnySSHCore
import Foundation
import Testing

@testable import Multiplexers

@Suite struct HerdrAdapterTests {
    @Test func parsesSnapshotPreferringForegroundCwdAndWorktree() throws {
        let parser = HerdrParser()
        let text = try MuxFixtureData.text("herdr-api-snapshot.json")
        let session = MuxSession(
            id: MuxSessionID(rawValue: "default"),
            name: "default",
            isAttached: true
        )
        let snapshot = try parser.snapshot(from: text, session: session)

        #expect(snapshot.groups.count == 1)
        #expect(snapshot.groups[0].id.rawValue == "w1:t1")
        #expect(snapshot.groups[0].title == "main")
        #expect(snapshot.groups[0].isActive)

        #expect(snapshot.panes.count == 2)
        #expect(snapshot.panes[0].workingDirectory == "/home/dev/src/api/services")
        #expect(snapshot.panes[0].agentStatus == "working")
        #expect(snapshot.panes[0].repositoryRoot == "/home/dev/src/api")
        #expect(snapshot.panes[0].isActive)
        #expect(snapshot.panes[1].workingDirectory == #"/home/dev/src/my project's "notes""#)
        #expect(snapshot.panes[1].agentStatus == "idle")
        #expect(snapshot.panes[1].repositoryRoot == "/home/dev/src/api")
    }

    @Test func nonDefaultNewTabBindingIsDiscoveredFromConfig() throws {
        let parser = HerdrParser()
        let config = try MuxFixtureData.text("herdr-config.toml")
        let bindings = parser.keyBindings(from: config)
        #expect(bindings.prefix == "ctrl+b")
        #expect(bindings.chords["new_tab"] == "prefix+t")
        #expect(bindings.chords["new_workspace"] == "prefix+shift+t")
    }

    @Test func aCustomDetachBindingIsDiscoveredFromConfig() {
        let parser = HerdrParser()
        let bindings = parser.keyBindings(
            from: """
                prefix = "ctrl+a"
                detach = "prefix+shift+d"
                """
        )
        #expect(bindings.prefix == "ctrl+a")
        #expect(bindings.chords["detach"] == "prefix+shift+d")
    }

    @Test func protocolSeventeenIsRefusedAsProtocolMismatch() async throws {
        let runner = ScriptedMuxRunner(sections: [
            HerdrCommands.detectLabel: try MuxFixtureData.bytes("herdr-status-protocol-17.json")
        ])
        let adapter = HerdrAdapter(runner: runner)
        do {
            _ = try await adapter.detect()
            Issue.record("expected protocol mismatch")
        } catch let error as ErrorState {
            #expect(error == .mux(.protocolMismatch))
            #expect(error.stateID == "mux.protocolMismatch")
        }
    }

    @Test func adapterDetectSessionsSnapshotAndAttach() async throws {
        let runner = ScriptedMuxRunner(sections: [
            HerdrCommands.detectLabel: try MuxFixtureData.bytes("herdr-status-client.json"),
            HerdrCommands.sessionsLabel: try MuxFixtureData.bytes("herdr-session-list.json"),
            HerdrCommands.snapshotLabel: try MuxFixtureData.bytes("herdr-api-snapshot.json"),
            HerdrCommands.configLabel: try MuxFixtureData.bytes("herdr-config.toml"),
            HerdrCommands.paneReadLabel: Data(
                #"{"result":{"read":{"text":"recent lines"}}}"#.utf8
            ),
        ])
        let adapter = HerdrAdapter(runner: runner)

        let info = try await adapter.detect()
        #expect(info.kind == .herdr)
        #expect(info.version == "0.8.0")
        #expect(info.protocolVersion == 19)
        #expect(info.binaryPath == "/home/dev/.local/bin/herdr")

        let sessions = try await adapter.listSessions()
        #expect(sessions.map(\.name) == ["default", "anyssh-test"])

        let snapshot = try await adapter.snapshot(MuxSessionID(rawValue: "default"))
        #expect(snapshot.panes[0].workingDirectory == "/home/dev/src/api/services")

        let bindings = try await adapter.keyBindings()
        #expect(bindings.chords["new_tab"] == "prefix+t")

        let text = try await adapter.readPane(MuxPaneID(rawValue: "w1:p1"), lines: 40)
        #expect(text == "recent lines")

        #expect(
            adapter.attachCommand(MuxTarget(session: MuxSessionID(rawValue: "anyssh-test")))
                == "'/home/dev/.local/bin/herdr' session attach 'anyssh-test'"
        )
        #expect(adapter.capabilities.localSessionSurvival == .proven)
        #expect(adapter.capabilities.remoteBootstrapSurvival == .unverified)
        #expect(adapter.capabilities.crossHostSurvival == .unverified)
    }

    @Test func focusingAPaneAsksTheAgentToTakeFocus() async throws {
        let runner = try focusRunner()
        let adapter = HerdrAdapter(runner: runner)

        try await adapter.focus(
            MuxTarget(
                session: MuxSessionID(rawValue: "default"),
                group: MuxGroupID(rawValue: "w18:t5"),
                pane: MuxPaneID(rawValue: "w18:p9")
            )
        )

        #expect(
            runner.batches.last?.commands.map(\.arguments) == [
                ["/home/dev/.local/bin/herdr", "agent", "focus", "w18:p9"]
            ]
        )
    }

    @Test func aRefusedAgentFocusFallsBackToTheTab() async throws {
        let runner = try focusRunner(agentExitCode: 1)
        let adapter = HerdrAdapter(runner: runner)

        try await adapter.focus(
            MuxTarget(
                session: MuxSessionID(rawValue: "default"),
                group: MuxGroupID(rawValue: "w18:t5"),
                pane: MuxPaneID(rawValue: "w18:p9")
            )
        )

        #expect(
            runner.batches.map { $0.commands.map(\.arguments) }.last == [
                ["/home/dev/.local/bin/herdr", "tab", "focus", "w18:t5"]
            ]
        )
    }

    @Test func focusingAGroupNamesTheNonDefaultSession() async throws {
        let runner = try focusRunner()
        let adapter = HerdrAdapter(runner: runner)

        try await adapter.focus(
            MuxTarget(
                session: MuxSessionID(rawValue: "anyssh-test"),
                group: MuxGroupID(rawValue: "w2:t1")
            )
        )

        #expect(
            runner.batches.last?.commands.map(\.arguments) == [
                [
                    "/home/dev/.local/bin/herdr", "--session", "anyssh-test", "tab", "focus",
                    "w2:t1",
                ]
            ]
        )
    }

    @Test func focusingASessionWithoutATargetIsRefused() async throws {
        let runner = try focusRunner()
        let adapter = HerdrAdapter(runner: runner)

        await #expect(throws: ErrorState.mux(.attachTargetVanished)) {
            try await adapter.focus(MuxTarget(session: MuxSessionID(rawValue: "default")))
        }
    }

    private func focusRunner(agentExitCode: Int32 = 0) throws -> ScriptedMuxRunner {
        ScriptedMuxRunner(
            sections: [
                HerdrCommands.detectLabel: try MuxFixtureData.bytes("herdr-status-client.json")
            ],
            exitCodes: [HerdrCommands.focusAgentLabel: agentExitCode]
        )
    }
}
