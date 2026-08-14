import AnySSHCore

public struct MultiplexerPathResolver: WorkspacePathResolver {
    private let adapter: any MultiplexerAdapter
    private let sessionID: MuxSessionID?

    public init(adapter: any MultiplexerAdapter, sessionID: MuxSessionID? = nil) {
        self.adapter = adapter
        self.sessionID = sessionID
    }

    public func resolve(_ session: SessionRecord) async -> WorkspaceLocation? {
        guard adapter.kind != .none, let sessionID else { return nil }
        guard let snapshot = try? await adapter.snapshot(sessionID) else { return nil }
        let activePane = snapshot.panes.first(where: \.isActive)
        guard let pane = activePane else { return nil }
        if adapter.kind == .herdr, let repositoryRoot = pane.repositoryRoot {
            return WorkspaceLocation(path: repositoryRoot, provenance: .multiplexer)
        }
        guard let path = pane.workingDirectory, !path.isEmpty else { return nil }
        return WorkspaceLocation(path: path, provenance: .multiplexer)
    }
}
