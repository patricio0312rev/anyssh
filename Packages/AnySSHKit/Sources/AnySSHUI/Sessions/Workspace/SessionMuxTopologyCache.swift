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
    private var latestRequests = [SessionID: Int]()

    func topology(for sessionID: SessionID) -> Topology {
        topologies[sessionID] ?? Topology()
    }

    func sessions(for sessionID: SessionID) -> [MuxSession] {
        topology(for: sessionID).sessions
    }

    func groups(for sessionID: SessionID) -> [MuxGroup] {
        topology(for: sessionID).groups
    }

    func beginRefresh(for sessionID: SessionID) -> Int {
        invalidateRequests(for: sessionID)
        return latestRequests[sessionID, default: 0]
    }

    func store(_ topology: Topology, for sessionID: SessionID, request: Int) {
        guard request == latestRequests[sessionID] else { return }
        topologies[sessionID] = topology
    }

    func markActive(_ group: MuxGroupID, for sessionID: SessionID) {
        guard var topology = topologies[sessionID], topology.groups.contains(where: { $0.id == group })
        else { return }
        topology.groups = topology.groups.map {
            MuxGroup(id: $0.id, sessionID: $0.sessionID, title: $0.title, isActive: $0.id == group)
        }
        topologies[sessionID] = topology
        invalidateRequests(for: sessionID)
    }

    func clear(for sessionID: SessionID) {
        topologies.removeValue(forKey: sessionID)
        invalidateRequests(for: sessionID)
    }

    private func invalidateRequests(for sessionID: SessionID) {
        latestRequests[sessionID, default: 0] += 1
    }
}
