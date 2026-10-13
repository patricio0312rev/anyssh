import AnySSHCore
import Foundation

public struct MultiplexerPathResolver: WorkspacePathResolver {
    private let adapter: any MultiplexerAdapter
    private let sessionID: MuxSessionID?
    private let runner: (any RemoteCommandRunner)?

    public init(
        adapter: any MultiplexerAdapter,
        sessionID: MuxSessionID? = nil,
        runner: (any RemoteCommandRunner)? = nil
    ) {
        self.adapter = adapter
        self.sessionID = sessionID
        self.runner = runner
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
        if adapter.kind == .herdr, let root = await repositoryRoot(containing: path) {
            return WorkspaceLocation(path: root, provenance: .multiplexer)
        }
        return WorkspaceLocation(path: path, provenance: .multiplexer)
    }

    private func repositoryRoot(containing path: String) async -> String? {
        guard let runner else { return nil }
        let batch = RemoteBatch(commands: [
            RemoteCommand(
                label: Self.rootLabel,
                arguments: GitCommand.repositoryRoot.invocation.arguments(in: path)
            )
        ])
        let response: BatchResponse
        do {
            response = try await runner.run(batch)
        } catch {
            return nil
        }
        guard let section = response.sections.first(where: { $0.label == Self.rootLabel }),
            section.exitCode == 0
        else { return nil }
        let root = String(decoding: section.bytes, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return root.isEmpty ? nil : root
    }

    private static let rootLabel = "multiplexer-root"
}
