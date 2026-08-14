public enum HeadState: Hashable, Sendable {
    case branch(String)
    case unborn(String)
    case detached(CommitID)
}

public struct UpstreamTracking: Hashable, Sendable {
    public let name: String
    public let ahead: Int
    public let behind: Int

    public init(name: String, ahead: Int, behind: Int) {
        self.name = name
        self.ahead = ahead
        self.behind = behind
    }
}

public struct RepositoryStatus: Hashable, Sendable {
    public let head: HeadState
    public let upstream: UpstreamTracking?
    public let staged: [ChangedFile]
    public let unstaged: [ChangedFile]
    public let untracked: [String]
    public let unmerged: [ChangedFile]

    public init(
        head: HeadState,
        upstream: UpstreamTracking?,
        staged: [ChangedFile],
        unstaged: [ChangedFile],
        untracked: [String],
        unmerged: [ChangedFile]
    ) {
        self.head = head
        self.upstream = upstream
        self.staged = staged
        self.unstaged = unstaged
        self.untracked = untracked
        self.unmerged = unmerged
    }
}
