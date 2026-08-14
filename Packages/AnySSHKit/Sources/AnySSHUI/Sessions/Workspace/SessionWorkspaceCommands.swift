import AnySSHCore
import Foundation
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
        guard let id = activeSessionID else { return }
        let probe = await probeSession(id)
        guard let directory = probe.directory else { return }
        registry.setWorkspace(WorkspaceLocation(path: directory, provenance: .process), for: id)
    }
}
