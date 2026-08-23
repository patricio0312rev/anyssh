import AnySSHCore

@MainActor
final class SessionMuxSessionCache {
    private var lists = [SessionID: [MuxSession]]()
    private var generations = [SessionID: Int]()

    func sessions(for sessionID: SessionID) -> [MuxSession] {
        lists[sessionID] ?? []
    }

    func generation(for sessionID: SessionID) -> Int {
        generations[sessionID] ?? 0
    }

    func store(_ sessions: [MuxSession], for sessionID: SessionID, generation: Int) {
        guard generation == self.generation(for: sessionID) else { return }
        lists[sessionID] = sessions
    }

    func clear(for sessionID: SessionID) {
        lists.removeValue(forKey: sessionID)
        generations[sessionID] = generation(for: sessionID) + 1
    }
}
