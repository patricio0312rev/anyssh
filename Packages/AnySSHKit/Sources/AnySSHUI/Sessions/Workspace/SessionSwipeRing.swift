import AnySSHCore

struct SessionSwipeRing: Sendable {
    enum Direction: Hashable, Sendable {
        case forward
        case backward
    }

    enum Target: Hashable, Sendable {
        case muxGroup(MuxGroupID)
        case muxSession(MuxSessionID)
        case appSession(SessionID)
    }

    private let elements: [Target]
    private let position: Int?

    init(
        muxSessions: [MuxSession],
        boundMuxSession: MuxSessionID?,
        boundGroups: [MuxGroup] = [],
        focusedGroup: MuxGroupID? = nil,
        appSessionIDs: [SessionID],
        activeSessionID: SessionID
    ) {
        let ordered = Self.ordered(muxSessions)
        let followers = Self.followers(of: activeSessionID, in: appSessionIDs).map(Target.appSession)
        let boundIndex = boundMuxSession.flatMap { binding in
            ordered.firstIndex { $0.id == binding }
        }
        let groups = boundMuxSession.map { Self.groups(boundGroups, of: $0) } ?? []
        if let index = boundIndex, groups.count > 1 {
            elements =
                groups.map { Target.muxGroup($0.id) }
                + Self.rotated(ordered, after: index).map { Target.muxSession($0.id) }
                + followers
            position = Self.anchor(in: groups, focused: focusedGroup)
        } else {
            elements = ordered.map { Target.muxSession($0.id) } + followers
            position = boundIndex
        }
    }

    func step(_ direction: Direction) -> Target? {
        guard !elements.isEmpty else { return nil }
        guard let position else { return atSeam(direction) }
        guard elements.count > 1 else { return nil }
        let delta = direction == .forward ? 1 : -1
        return elements[(position + delta + elements.count) % elements.count]
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

    private static func groups(_ groups: [MuxGroup], of session: MuxSessionID) -> [MuxGroup] {
        groups.filter { $0.sessionID == session }
    }

    private static func rotated(_ sessions: [MuxSession], after index: Int) -> [MuxSession] {
        Array(sessions[sessions.index(after: index)...]) + Array(sessions[..<index])
    }

    private static func anchor(in groups: [MuxGroup], focused: MuxGroupID?) -> Int {
        if let index = groups.firstIndex(where: \.isActive) { return index }
        if let focused, let index = groups.firstIndex(where: { $0.id == focused }) { return index }
        return 0
    }
}
