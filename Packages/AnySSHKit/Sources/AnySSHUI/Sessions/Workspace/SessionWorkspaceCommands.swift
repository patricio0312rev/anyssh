import AnySSHCore
import Foundation
import GitClient
import Multiplexers
import Sessions
import TerminalEmulator

extension SessionWorkspaceModel {
    public func toggleGridMode() { isGridMode.toggle() }

    public func dismissOpenFailure() {
        clearOpenFailure()
    }

    public func retryActiveSession() async {
        if let record = activeRecord,
            registry.reconnectState(for: record.id)?.offersReconnect == true
        {
            dismissOpenFailure()
            await reconnect(record.id, forced: true)
            return
        }
        guard let remoteID = openFailureRemoteID, let remote = remotes[remoteID] else { return }
        dismissOpenFailure()
        await open(remote: remote)
    }

    public func sendMultiplexerChord(_ text: String, on connection: any RemoteConnection) async {
        guard let chord = try? Chord(parsing: text) else { return }
        let bytes = KeyEncoder().encode(chord)
        guard !bytes.isEmpty else { return }
        try? await connection.sendDisplay(bytes[...])
    }

    public func refreshAgentKinds() async {
        for id in registry.ids {
            await detectAgent(for: id)
        }
    }

    public func resolveWorkspaceForActiveSession() async {
        guard let id = activeSessionID, let record = record(for: id) else { return }
        if let location = await resolveWorkspace(for: record) {
            applyWorkspace(location, to: id)
        }
    }

    func resolveWorkspace(for record: SessionRecord) async -> WorkspaceLocation? {
        if let adapter = sessionAdapters[record.id] ?? multiplexerAdapter,
            let location = await resolveMultiplexerWorkspace(adapter: adapter, record: record)
        {
            return location
        }
        let probe = await probeSession(record.id)
        return probe.directory.map { WorkspaceLocation(path: $0, provenance: .process) }
    }

    func resolveMultiplexerWorkspace(
        adapter: any MultiplexerAdapter,
        record: SessionRecord
    ) async -> WorkspaceLocation? {
        guard let sessions = try? await adapter.listSessions(),
            let muxSession = sessions.first(where: { $0.isAttached }) ?? sessions.first
        else { return nil }
        return await MultiplexerPathResolver(adapter: adapter, sessionID: muxSession.id)
            .resolve(record)
    }

    func applyWorkspace(_ location: WorkspaceLocation, to sessionID: SessionID) {
        registry.setWorkspace(location, for: sessionID)
        if let remoteID = record(for: sessionID)?.remoteID {
            lastDirectories.remember(location.path, for: remoteID)
        }
    }
}
