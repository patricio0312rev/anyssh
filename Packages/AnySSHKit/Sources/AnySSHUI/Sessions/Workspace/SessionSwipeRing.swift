import AnySSHCore

struct SessionSwipeRing: Sendable {
    enum Direction: Hashable, Sendable {
        case forward
        case backward
    }

    enum Target: Hashable, Sendable {
        case muxSession(MuxSessionID)
        case appSession(SessionID)
    }

    private let elements: [Target]
    private let boundIndex: Int?

    init(
        muxSessions: [MuxSession],
        boundMuxSession: MuxSessionID?,
        appSessionIDs: [SessionID],
        activeSessionID: SessionID
    ) {
        let ordered = Self.ordered(muxSessions)
        let followers = Self.followers(of: activeSessionID, in: appSessionIDs)
        elements = ordered.map { Target.muxSession($0.id) } + followers.map(Target.appSession)
        boundIndex = boundMuxSession.flatMap { binding in
            ordered.firstIndex { $0.id == binding }
        }
    }

    func step(_ direction: Direction) -> Target? {
        guard !elements.isEmpty else { return nil }
        guard let boundIndex else { return atSeam(direction) }
        guard elements.count > 1 else { return nil }
        let delta = direction == .forward ? 1 : -1
        return elements[(boundIndex + delta + elements.count) % elements.count]
    }

    private func atSeam(_ direction: Direction) -> Target? {
        switch direction {
        case .forward: elements.first
        case .backward: elements.last
        }
    }

    private static func ordered(_ sessions: [MuxSession]) -> [MuxSession] {
        sessions.sorted { left, right in
            left.name == right.name
                ? left.id.rawValue < right.id.rawValue
                : left.name < right.name
        }
    }

    private static func followers(of active: SessionID, in ids: [SessionID]) -> [SessionID] {
        guard let index = ids.firstIndex(of: active) else { return ids.filter { $0 != active } }
        return Array(ids[ids.index(after: index)...]) + Array(ids[..<index])
    }
}
