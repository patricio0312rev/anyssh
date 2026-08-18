import AnySSHCore
import Foundation
import Multiplexers
import SSHTransport
import Sessions

extension SessionWorkspaceModel {
    func configureMultiplexer(for sessionID: SessionID, connection: any RemoteConnection) async {
        guard let capabilities = try? await SSHCapabilityProbe(runner: connection).probe() else {
            await detectAgent(for: sessionID)
            return
        }
        replaceMultiplexer(for: sessionID, with: adapter(for: capabilities, connection: connection))
        await detectAgent(for: sessionID)
    }

    func replaceMultiplexer(for sessionID: SessionID, with adapter: (any MultiplexerAdapter)?) {
        stallWatchers.removeValue(forKey: sessionID)?.cancel()
        sessionAdapters[sessionID] = adapter
        guard let adapter else { return }
        startStallWatcher(for: sessionID, adapter: adapter)
    }

    func adapter(
        for capabilities: HostCapabilities,
        connection: any RemoteConnection
    ) -> (any MultiplexerAdapter)? {
        if capabilities.herdr.isProtocolSupported {
            return HerdrAdapter(runner: connection, binaryPath: capabilities.herdr.tool.path)
        }
        if capabilities.tmux.isAvailable {
            return TmuxAdapter(
                runner: connection,
                binaryPath: capabilities.tmux.path ?? Self.tmuxFallbackPath
            )
        }
        return nil
    }

    func startStallWatcher(for sessionID: SessionID, adapter: any MultiplexerAdapter) {
        guard let scheduler = jobAlerts else { return }
        let scope = scopes[sessionID]
        stallWatchers[sessionID] = Task {
            let sessions = (try? await adapter.listSessions()) ?? []
            guard let muxSession = sessions.first(where: { $0.isAttached }) ?? sessions.first
            else { return }
            let watcher = HerdrStallWatcher(
                sessionID: sessionID,
                scheduler: scheduler,
                onState: { [weak self] state in
                    Task { @MainActor [weak self] in
                        self?.agentStates[sessionID] = state
                        self?.updateActivity(for: sessionID)
                    }
                }
            )
            let poller = MuxTopologyPoller(adapter: adapter)
            try? await poller.pollLoop(
                session: muxSession.id,
                run: { operation in
                    guard let scope else { return try await operation() }
                    return try await scope.run(operation)
                },
                onSnapshot: { snapshot in
                    await watcher.ingest(snapshot)
                }
            )
        }
    }

    func detectAgent(for sessionID: SessionID) async {
        let detector = AgentKindDetector()
        let terminalTitle = registry[sessionID]?.title
        let probe = await probeSession(sessionID)
        if let directory = probe.directory {
            registry.setWorkspace(
                WorkspaceLocation(path: directory, provenance: .process),
                for: sessionID
            )
            if let remoteID = record(for: sessionID)?.remoteID {
                lastDirectories.remember(directory, for: remoteID)
            }
        }
        if let kind = detector.detect(processNames: probe.processNames) {
            sessionAgentKinds[sessionID] = kind
            return
        }
        guard let adapter = sessionAdapters[sessionID] else {
            sessionAgentKinds[sessionID] = detector.detect(terminalTitle: terminalTitle)
            return
        }
        sessionAgentKinds[sessionID] = await detectAgent(
            detector: detector,
            adapter: adapter,
            terminalTitle: terminalTitle
        )
    }

    func detectAgent(
        detector: AgentKindDetector,
        adapter: any MultiplexerAdapter,
        terminalTitle: String?
    ) async -> AgentKind? {
        guard let sessions = try? await adapter.listSessions(),
            let muxSession = sessions.first(where: { $0.isAttached }) ?? sessions.first,
            let snapshot = try? await adapter.snapshot(muxSession.id)
        else {
            return detector.detect(terminalTitle: terminalTitle)
        }
        let pane = snapshot.panes.first(where: { $0.isActive }) ?? snapshot.panes.first
        return detector.detect(
            signals: [pane?.title, pane?.agentStatus, muxSession.name, terminalTitle].compactMap {
                $0
            }
        )
    }

    func multiplexerName(for sessionID: SessionID) -> String? {
        switch sessionAdapters[sessionID]?.kind ?? multiplexerAdapter?.kind {
        case .herdr: "herdr"
        case .tmux: "tmux"
        default: nil
        }
    }

    static let tmuxFallbackPath = "tmux"
}
