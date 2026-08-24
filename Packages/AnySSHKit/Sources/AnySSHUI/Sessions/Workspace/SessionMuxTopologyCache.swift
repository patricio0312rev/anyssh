import AnySSHCore

@MainActor
final class SessionMuxTopologyCache {
    struct Topology: Equatable, Sendable {
        var sessions: [MuxSession]
        var groups: [MuxGroup]

        init(sessions: [MuxSession] = [], groups: [MuxGroup] = []) {
            self.sessions = sessions
            self.groups = groups
        }
    }

    private var topologies = [SessionID: Topology]()
    private var generations = [SessionID: Int]()

    func topology(for sessionID: SessionID) -> Topology {
        topologies[sessionID] ?? Topology()
    }

    func sessions(for sessionID: SessionID) -> [MuxSession] {
        topology(for: sessionID).sessions
    }

    func groups(for sessionID: SessionID) -> [MuxGroup] {
        topology(for: sessionID).groups
    }

    func generation(for sessionID: SessionID) -> Int {
        generations[sessionID] ?? 0
    }

    func store(_ topology: Topology, for sessionID: SessionID, generation: Int) {
        guard generation == self.generation(for: sessionID) else { return }
        topologies[sessionID] = topology
    }

    func clear(for sessionID: SessionID) {
        topologies.removeValue(forKey: sessionID)
        generations[sessionID] = generation(for: sessionID) + 1
    }
}
