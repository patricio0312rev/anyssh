import AnySSHCore

public struct DefaultPathResolver: WorkspacePathResolver {
    private let path: String

    public init(path: String? = nil) { self.path = path ?? "$HOME" }

    public func resolve(_ session: SessionRecord) async -> WorkspaceLocation? {
        WorkspaceLocation(path: path, provenance: .default)
    }
}
