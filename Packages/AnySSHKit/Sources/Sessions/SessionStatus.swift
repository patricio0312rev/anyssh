import AnySSHCore

public enum SessionStatus: Hashable, Sendable {
    case idle
    case connecting
    case connected(TerminalSize)
    case disconnected(reason: String)

    public var isLive: Bool {
        if case .connected = self { return true }
        return false
    }
}

public struct SessionDescriptor: Identifiable, Hashable, Sendable {
    public let id: String
    public let remoteID: RemoteID
    public var status: SessionStatus

    public init(id: String, remoteID: RemoteID, status: SessionStatus = .idle) {
        self.id = id
        self.remoteID = remoteID
        self.status = status
    }
}
