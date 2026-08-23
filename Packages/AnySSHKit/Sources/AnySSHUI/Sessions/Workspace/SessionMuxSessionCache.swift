import AnySSHCore

@MainActor
final class SessionMuxSessionCache {
    private var lists = [SessionID: [MuxSession]]()

    func sessions(for sessionID: SessionID) -> [MuxSession] {
        lists[sessionID] ?? []
    }

    func store(_ sessions: [MuxSession], for sessionID: SessionID) {
        lists[sessionID] = sessions
    }

    func clear(for sessionID: SessionID) {
        lists.removeValue(forKey: sessionID)
    }
}
