public protocol GitService: Sendable {
    func repository(at location: WorkspaceLocation) async throws -> RepositoryRef
    func status(of repository: RepositoryRef) async throws -> RepositoryStatus
    func diff(
        for file: ChangedFile,
        in repository: RepositoryRef,
        staged: Bool
    ) async throws -> FileDiff
    func history(
        of repository: RepositoryRef,
        before: CommitID?,
        limit: Int
    ) async throws -> [Commit]
    func diff(for commit: CommitID, in repository: RepositoryRef) async throws -> [FileDiff]
    func diff(forUntracked path: String, in repository: RepositoryRef) async throws -> FileDiff
}
