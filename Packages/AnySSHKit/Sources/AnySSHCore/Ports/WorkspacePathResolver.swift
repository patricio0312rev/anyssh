public protocol WorkspacePathResolver: Sendable {
    func resolve(_ session: SessionRecord) async -> WorkspaceLocation?
}
