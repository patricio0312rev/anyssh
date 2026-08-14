import Foundation

public struct SessionID: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct ConnectionID: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct SessionRecord: Identifiable, Equatable, Sendable {
    public let id: SessionID
    public let remoteID: RemoteID
    public let connectionID: ConnectionID
    public var title: String
    public var state: TransportState
    public var capabilities: TransportCapabilities
    public var reconnectAttempts: Int
    public let createdAt: Date
    public var lastActiveAt: Date
    public var workspace: WorkspaceLocation?

    public init(
        id: SessionID,
        remoteID: RemoteID,
        connectionID: ConnectionID,
        title: String,
        state: TransportState,
        capabilities: TransportCapabilities,
        reconnectAttempts: Int = 0,
        createdAt: Date,
        lastActiveAt: Date,
        workspace: WorkspaceLocation? = nil
    ) {
        self.id = id
        self.remoteID = remoteID
        self.connectionID = connectionID
        self.title = title
        self.state = state
        self.capabilities = capabilities
        self.reconnectAttempts = reconnectAttempts
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.workspace = workspace
    }
}
