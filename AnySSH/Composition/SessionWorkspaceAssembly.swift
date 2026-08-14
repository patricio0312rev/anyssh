import AnySSHCore
import AnySSHMocks
import AnySSHUI
import Foundation
import Multiplexers
import Sessions

@MainActor
enum SessionWorkspaceAssembly {
    static func make(_ scenario: WorkspaceScenario) -> SessionWorkspaceView {
        let records = SessionScenario.records(scenario.recordsFixture)
        let remotes = RemoteFixtures.scenario("mixed")
        let mux = muxContext(for: scenario)
        var connections = [SessionID: any RemoteConnection]()
        for record in records {
            connections[record.id] = MockRemoteConnection(
                connectionID: record.connectionID,
                displayScript: scenario.alertScript
            )
        }
        let model = SessionWorkspaceModel(
            registry: SessionRegistry(records),
            remotes: remotes,
            activeSessionID: activeSession(in: records, for: scenario),
            connections: connections,
            makeEngine: { size in SwiftTermEngine(size: size, renderer: .metal) },
            multiplexerKind: mux.kind,
            muxBindings: mux.bindings,
            multiplexerAdapter: mux.adapter,
            layoutDirectory: layoutDirectory(for: scenario),
            jobAlertScheduler: RecordingNotificationScheduler(),
            makeBrowserServices: { _, _ in mockBrowserServices }
        )
        seedTranscripts(in: model, records: records, for: scenario)
        attachDisplays(in: model, records: records, for: scenario)
        raiseKeyboard(in: model, records: records, for: scenario)
        return SessionWorkspaceView(
            model: model,
            initialSurface: scenario.surface,
            pinsAccessoryBar: scenario.forcesAccessoryBar
        )
    }

    private static func attachDisplays(
        in model: SessionWorkspaceModel,
        records: [SessionRecord],
        for scenario: WorkspaceScenario
    ) {
        guard scenario.deliversAlerts else { return }
        for record in records {
            guard let surface = model.surface(for: record.id),
                let connection = model.connection(for: record.id)
            else { continue }
            let size = surface.engine.size
            Task { try? await connection.attachDisplay(sink: surface.pump, size: size) }
        }
    }

    private static func raiseKeyboard(
        in model: SessionWorkspaceModel,
        records: [SessionRecord],
        for scenario: WorkspaceScenario
    ) {
        guard scenario.forcesAccessoryBar else { return }
        for record in records {
            model.surface(for: record.id)?.engine.wantsKeyboard = true
        }
        guard let active = model.activeSessionID,
            let engine = model.surface(for: active)?.engine
        else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            _ = engine.surface.becomeFirstResponder()
        }
    }

    private static func seedTranscripts(
        in model: SessionWorkspaceModel,
        records: [SessionRecord],
        for scenario: WorkspaceScenario
    ) {
        let transcript = scenario.transcript
        for record in records {
            model.surface(for: record.id)?.engine.feed(ArraySlice(transcript))
        }
    }

    static let mockBrowserServices: SessionWorkspaceModel.BrowserServices = (
        MockGitService(.dirty), MockRemoteFileBrowser(.populated)
    )

    private static func activeSession(
        in records: [SessionRecord],
        for scenario: WorkspaceScenario
    ) -> SessionID? {
        if scenario.isMultiplexed {
            return records.first(where: { $0.title.contains("tmux") })?.id ?? records.first?.id
        }
        if scenario == .reconnect {
            let disconnected = records.first {
                if case .disconnected = $0.state { return true }
                return false
            }
            return disconnected?.id ?? records.first?.id
        }
        return records.first?.id
    }

    private static func muxContext(for scenario: WorkspaceScenario) -> (
        kind: MultiplexerKind,
        bindings: MuxKeyBindings?,
        adapter: (any MultiplexerAdapter)?
    ) {
        switch scenario {
        case .tmux:
            (
                .tmux,
                MuxKeyBindings(prefix: "C-a", chords: [:]),
                FixtureMultiplexerAdapter(fixture: .tmuxMain)
            )
        case .herdr:
            (
                .herdr,
                MuxKeyBindings(
                    prefix: "ctrl+a",
                    chords: ["new_tab": "prefix+t", "detach": "prefix+shift+d"]
                ),
                FixtureMultiplexerAdapter(fixture: .herdrDefault)
            )
        default:
            (.none, nil, nil)
        }
    }

    private static func layoutDirectory(for scenario: WorkspaceScenario) -> URL {
        URL.applicationSupportDirectory
            .appending(path: "AnySSH")
            .appending(path: "MockJump")
            .appending(path: scenario.rawValue)
    }
}
