import AnySSHCore
import Sessions

extension SessionWorkspaceModel {
    func reattachMultiplexer(
        _ sessionID: SessionID,
        remote: Remote,
        connection: any RemoteConnection
    ) async throws {
        guard StartupCommandSender().payload(from: remote) == nil,
            let adapter = sessionAdapters[sessionID],
            let sessions = try? await adapter.listSessions(),
            let target = muxSession(in: sessions, for: sessionID)
        else { return }
        let probe = await probeSession(sessionID)
        guard FreshLoginShell.isAtPrompt(processNames: probe.processNames) else { return }
        let bytes = MuxNavigator(adapter: adapter, writer: connection, probe: { .detached })
            .attachBytes(for: MuxTarget(session: target.id))
        guard !bytes.isEmpty else { return }
        try await connection.sendDisplay(bytes[...])
        sessionsInsideMux.insert(sessionID)
    }
}
