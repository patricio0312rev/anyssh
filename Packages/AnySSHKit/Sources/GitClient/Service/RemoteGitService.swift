import AnySSHCore
import Foundation

public actor RemoteGitService: GitService {
    private let runner: any RemoteCommandRunner
    private let resolver: GitRootResolver
    private var repositories = [String: RepositoryRef]()

    private let remoteID: RemoteID

    public init(runner: any RemoteCommandRunner, remoteID: RemoteID = RemoteID(rawValue: "remote")) {
        self.runner = runner
        resolver = GitRootResolver(runner: runner)
        self.remoteID = remoteID
    }

    public func repository(at location: WorkspaceLocation) async throws -> RepositoryRef {
        let key = remoteID.rawValue + "\u{1}" + location.path
        if let cached = repositories[key] { return cached }
        let repository = try await resolver.resolve(location, remoteID: remoteID)
        repositories[key] = repository
        return repository
    }

    public func status(of repository: RepositoryRef) async throws -> RepositoryStatus {
        let response = try await runner.run(
            RemoteBatch(commands: [
                RemoteCommand(
                    label: "status",
                    arguments: GitCommand.status.invocation.arguments(in: repository.root)
                ),
                RemoteCommand(
                    label: "unstaged",
                    arguments: GitCommand.unstagedNumstat.invocation.arguments(in: repository.root)
                ),
                RemoteCommand(
                    label: "staged",
                    arguments: GitCommand.stagedNumstat.invocation.arguments(in: repository.root)
                ),
            ]))
        guard let section = response.sections.first else { throw GitParserError.state(.git(.missing)) }
        let status = try StatusParser().parse(section.bytes)
        let counts = { (label: String) -> [ChangedFile] in
            guard let bytes = response.sections.first(where: { $0.label == label })?.bytes,
                let files = try? NumstatParser().parse(bytes)
            else { return [] }
            return files
        }
        return RepositoryStatus(
            head: status.head,
            upstream: status.upstream,
            staged: NumstatMerge.apply(counts("staged"), to: status.staged),
            unstaged: NumstatMerge.apply(counts("unstaged"), to: status.unstaged),
            untracked: status.untracked,
            unmerged: status.unmerged
        )
    }

    public func diff(for file: ChangedFile, in repository: RepositoryRef, staged: Bool) async throws
        -> FileDiff
    {
        let command = GitCommand.perFileDiff(pathspec: file.pathspec, staged: staged)
        let response = try await runner.run(
            RemoteBatch(commands: [
                RemoteCommand(
                    label: "patch",
                    arguments: command.invocation.arguments(in: repository.root),
                    byteCap: 262_144
                )
            ]))
        guard let section = response.sections.first else { throw GitParserError.state(.git(.diffTruncated)) }
        return try DiffParser().parse(section.bytes, file: file)
    }

    public func history(of repository: RepositoryRef, before: CommitID?, limit: Int) async throws -> [Commit]
    {
        let command =
            before.map { GitCommand.logBefore(limit: limit, commit: $0) }
            ?? GitCommand.log(limit: limit, skip: 0)
        let response = try await runner.run(
            RemoteBatch(commands: [
                RemoteCommand(
                    label: "log",
                    arguments: command.invocation.arguments(in: repository.root)
                )
            ]))
        guard let section = response.sections.first else { return [] }
        return try LogParser().parse(section.bytes)
    }

    public func diff(forUntracked path: String, in repository: RepositoryRef) async throws -> FileDiff {
        let response = try await runner.run(
            RemoteBatch(commands: [
                RemoteCommand(
                    label: "untracked",
                    arguments: GitCommand.untrackedDiff(path: path).invocation
                        .arguments(in: repository.root),
                    byteCap: 262_144
                )
            ]))
        guard let section = response.sections.first, !section.bytes.isEmpty else {
            throw GitParserError.state(.git(.missing))
        }
        let file = ChangedFile(oldPath: nil, newPath: path, change: .added, isBinary: false)
        return try DiffParser().parse(section.bytes, file: file)
    }

    public func diff(for commit: CommitID, in repository: RepositoryRef) async throws -> [FileDiff] {
        let command = GitCommand.commitPatch(oid: commit.rawValue)
        let response = try await runner.run(
            RemoteBatch(commands: [
                RemoteCommand(
                    label: "commit",
                    arguments: command.invocation.arguments(in: repository.root),
                    byteCap: 512 * 1024
                )
            ]))
        guard let section = response.sections.first else { throw GitParserError.state(.git(.missing)) }
        if section.bytes.starts(with: Data("diff --cc".utf8)) {
            throw GitParserError.state(.git(.combinedDiffUnsupported))
        }
        return PatchSplitter.split(section.bytes).compactMap { segment in
            try? DiffParser().parse(segment.patch, file: segment.file)
        }
    }
}
