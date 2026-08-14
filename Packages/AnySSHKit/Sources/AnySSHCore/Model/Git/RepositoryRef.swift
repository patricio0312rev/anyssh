public struct RepositoryRef: Hashable, Sendable {
    public let remoteID: RemoteID
    public let root: String
    public let gitDir: String

    public init(remoteID: RemoteID, root: String, gitDir: String) {
        self.remoteID = remoteID
        self.root = root
        self.gitDir = gitDir
    }
}
