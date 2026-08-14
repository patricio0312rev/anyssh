import AnySSHCore

public struct GitRootResolver: Sendable {
    private let runner: any RemoteCommandRunner

    public init(runner: any RemoteCommandRunner) { self.runner = runner }

    public func resolve(_ location: WorkspaceLocation, remoteID: RemoteID) async throws -> RepositoryRef {
        let response = try await runner.run(
            RemoteBatch(commands: [
                RemoteCommand(
                    label: "root",
                    arguments: GitCommand.repositoryRoot.invocation.arguments(in: location.path)
                ),
                RemoteCommand(
                    label: "git-dir",
                    arguments: GitCommand.gitDirectory.invocation.arguments(in: location.path)
                ),
            ]))
        guard let root = response.sections.first(where: { $0.label == "root" }), root.exitCode == 0,
            let gitDir = response.sections.first(where: { $0.label == "git-dir" }), gitDir.exitCode == 0
        else {
            throw GitParserError.state(.git(.notARepository))
        }
        return RepositoryRef(
            remoteID: remoteID,
            root: String(decoding: root.bytes, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines),
            gitDir: String(decoding: gitDir.bytes, as: UTF8.self).trimmingCharacters(
                in: .whitespacesAndNewlines))
    }
}
