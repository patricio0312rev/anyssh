public enum MultiplexerKind: String, CaseIterable, Sendable {
    case none
    case tmux
    case herdr
}

public struct MuxSessionID: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct MuxGroupID: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct MuxPaneID: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct MuxSession: Identifiable, Hashable, Sendable {
    public let id: MuxSessionID
    public let name: String
    public let isAttached: Bool

    public init(id: MuxSessionID, name: String, isAttached: Bool) {
        self.id = id
        self.name = name
        self.isAttached = isAttached
    }
}

public struct MuxGroup: Identifiable, Hashable, Sendable {
    public let id: MuxGroupID
    public let sessionID: MuxSessionID
    public let title: String
    public let isActive: Bool

    public init(id: MuxGroupID, sessionID: MuxSessionID, title: String, isActive: Bool) {
        self.id = id
        self.sessionID = sessionID
        self.title = title
        self.isActive = isActive
    }
}

public struct MuxPane: Identifiable, Hashable, Sendable {
    public let id: MuxPaneID
    public let groupID: MuxGroupID
    public let title: String
    public let workingDirectory: String?
    public let isActive: Bool
    public let agentStatus: String?
    public let repositoryRoot: String?

    public init(
        id: MuxPaneID,
        groupID: MuxGroupID,
        title: String,
        workingDirectory: String?,
        isActive: Bool,
        agentStatus: String?,
        repositoryRoot: String?
    ) {
        self.id = id
        self.groupID = groupID
        self.title = title
        self.workingDirectory = workingDirectory
        self.isActive = isActive
        self.agentStatus = agentStatus
        self.repositoryRoot = repositoryRoot
    }
}

public struct MuxSnapshot: Hashable, Sendable {
    public let session: MuxSession
    public let groups: [MuxGroup]
    public let panes: [MuxPane]

    public init(session: MuxSession, groups: [MuxGroup], panes: [MuxPane]) {
        self.session = session
        self.groups = groups
        self.panes = panes
    }
}

public struct MuxTarget: Hashable, Sendable {
    public let session: MuxSessionID
    public let group: MuxGroupID?
    public let pane: MuxPaneID?

    public init(session: MuxSessionID, group: MuxGroupID? = nil, pane: MuxPaneID? = nil) {
        self.session = session
        self.group = group
        self.pane = pane
    }
}
