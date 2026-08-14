import AnySSHCore

public struct ProcessPathResolver: WorkspacePathResolver {
    private let location: WorkspaceLocation?

    public init(path: String?) { location = path.map { WorkspaceLocation(path: $0, provenance: .process) } }

    public func resolve(_ session: SessionRecord) async -> WorkspaceLocation? { location }
}
