public protocol FileTreeService: Sendable {
    func tree(repository: RepositoryRef, ref: String) async throws -> FileTree
}
