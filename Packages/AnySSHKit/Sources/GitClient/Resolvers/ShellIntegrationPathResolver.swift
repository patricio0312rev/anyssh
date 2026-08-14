import AnySSHCore

public struct ShellIntegrationPathResolver: WorkspacePathResolver {
    private let location: WorkspaceLocation?

    public init(path: String?) {
        location = path.map { WorkspaceLocation(path: $0, provenance: .shellIntegration) }
    }

    public func resolve(_ session: SessionRecord) async -> WorkspaceLocation? { location }
}
