import AnySSHCore

public struct GitRepositoryRef: Hashable, Sendable {
    public let remoteID: RemoteID
    public let path: String
    public let branch: String

    public init(remoteID: RemoteID, path: String, branch: String = "main") {
        self.remoteID = remoteID
        self.path = path
        self.branch = branch
    }
}
