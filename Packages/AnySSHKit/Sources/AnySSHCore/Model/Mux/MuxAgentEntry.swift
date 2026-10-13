public struct MuxAgentEntry: Identifiable, Hashable, Sendable {
    public let id: MuxPaneID
    public let sessionID: MuxSessionID
    public let groupID: MuxGroupID
    public let title: String
    public let detail: String?
    public let tabTitle: String?
    public let kind: AgentKind?
    public let status: String?
    public let isActive: Bool

    public init(
        id: MuxPaneID,
        sessionID: MuxSessionID,
        groupID: MuxGroupID,
        title: String,
        detail: String?,
        tabTitle: String?,
        kind: AgentKind?,
        status: String?,
        isActive: Bool
    ) {
        self.id = id
        self.sessionID = sessionID
        self.groupID = groupID
        self.title = title
        self.detail = detail
        self.tabTitle = tabTitle
        self.kind = kind
        self.status = status
        self.isActive = isActive
    }

    public var target: MuxTarget {
        MuxTarget(session: sessionID, group: groupID, pane: id)
    }
}
