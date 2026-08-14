import Foundation

public protocol ActivityPresenter: Sendable {
    func start(_ content: ActivityContent) async
    func update(_ content: ActivityContent) async
    func end(_ content: ActivityContent) async
}

public struct ActivityContent: Hashable, Sendable {
    public let sessionID: SessionID
    public let title: String
    public let remoteName: String
    public let transportState: String
    public let agentState: String
    public let uptime: TimeInterval
    public let notification: String?
    public let updatedAt: Date
    public let staleDate: Date

    public init(
        sessionID: SessionID,
        title: String,
        remoteName: String,
        transportState: String,
        agentState: String = "idle",
        uptime: TimeInterval,
        notification: String? = nil,
        updatedAt: Date,
        staleDate: Date
    ) {
        self.sessionID = sessionID
        self.title = title
        self.remoteName = remoteName
        self.transportState = transportState
        self.agentState = agentState
        self.uptime = uptime
        self.notification = notification
        self.updatedAt = updatedAt
        self.staleDate = staleDate
    }
}
