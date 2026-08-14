import AnySSHCore

public struct JumpRow: Identifiable, Hashable, Sendable {
    public let group: MuxGroup
    public let status: JumpAgentStatus
    public let paneCount: Int

    public var id: MuxGroupID { group.id }
    public var title: String { group.title }
    public var isActive: Bool { group.isActive }
    public var sessionID: MuxSessionID { group.sessionID }

    public init(group: MuxGroup, status: JumpAgentStatus, paneCount: Int) {
        self.group = group
        self.status = status
        self.paneCount = paneCount
    }
}

public struct JumpSession: Identifiable, Hashable, Sendable {
    public let id: MuxSessionID
    public let name: String
    public let groups: [JumpRow]

    public init(id: MuxSessionID, name: String, groups: [JumpRow]) {
        self.id = id
        self.name = name
        self.groups = groups
    }
}

public enum JumpAgentStatus: Hashable, Sendable {
    case waiting(String)
    case finished(String)
    case unknown

    public var isWaiting: Bool {
        if case .waiting = self { return true }
        return false
    }

    public var valueText: String {
        switch self {
        case .waiting(let value), .finished(let value): value
        case .unknown: ""
        }
    }

    public init(rawValue: String) {
        switch rawValue.lowercased() {
        case "working": self = .waiting("working")
        case "blocked": self = .waiting("blocked")
        case "idle": self = .finished("idle")
        case "done": self = .finished("done")
        default: self = .unknown
        }
    }
}

public enum JumpTreeBuilder {
    public static func build(
        sessions: [MuxSession],
        snapshots: [MuxSessionID: MuxSnapshot]
    ) -> [JumpSession] {
        sessions.compactMap { session in
            guard let snapshot = snapshots[session.id] else { return nil }
            let rows = snapshot.groups.map { group in
                JumpRow(
                    group: group,
                    status: status(of: group, in: snapshot),
                    paneCount: snapshot.panes.filter { $0.groupID == group.id }.count
                )
            }
            return JumpSession(id: session.id, name: session.name, groups: rows)
        }
    }

    public static func status(of group: MuxGroup, in snapshot: MuxSnapshot) -> JumpAgentStatus {
        let statuses = snapshot.panes
            .filter { $0.groupID == group.id }
            .compactMap { $0.agentStatus }
            .map(JumpAgentStatus.init(rawValue:))
            .filter { $0 != .unknown }
        guard let worst = statuses.max(by: { rank($0) < rank($1) }) else { return .unknown }
        return worst
    }

    private static func rank(_ status: JumpAgentStatus) -> Int {
        switch status {
        case .waiting(let value): value == "blocked" ? 3 : 2
        case .finished: 1
        case .unknown: 0
        }
    }
}
