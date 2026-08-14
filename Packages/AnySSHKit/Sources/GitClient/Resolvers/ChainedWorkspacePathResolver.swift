import AnySSHCore

public struct ChainedWorkspacePathResolver: WorkspacePathResolver {
    private let resolvers: [any WorkspacePathResolver]

    public init(_ resolvers: [any WorkspacePathResolver]) { self.resolvers = resolvers }

    public func resolve(_ session: SessionRecord) async -> WorkspaceLocation? {
        for resolver in resolvers {
            if let location = await resolver.resolve(session) { return location }
        }
        return nil
    }
}
