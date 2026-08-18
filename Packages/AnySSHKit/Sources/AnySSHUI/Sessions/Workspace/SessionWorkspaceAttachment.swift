import AnySSHCore
import Sessions

extension SessionWorkspaceModel {
    func attachmentProbe(for sessionID: SessionID) -> MuxNavigator.AttachmentProbe {
        { [weak self] in await self?.attachment(of: sessionID) ?? .unknown }
    }

    func attachment(of sessionID: SessionID) async -> MuxAttachment {
        let probe = await probeSession(sessionID)
        guard !probe.processNames.isEmpty else { return .unknown }
        guard AgentKindDetector().detectMultiplexer(processNames: probe.processNames) != nil
        else { return .detached }
        guard let adapter = sessionAdapters[sessionID] ?? multiplexerAdapter,
            let sessions = try? await adapter.listSessions()
        else { return .attached(nil) }
        return .attached(muxSession(in: sessions, for: sessionID)?.id)
    }
}
