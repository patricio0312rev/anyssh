import AnySSHCore
import Foundation

public struct MockGitService: GitService {
    public enum Scenario: String, Sendable, CaseIterable {
        case dirty
        case clean
        case newFile
        case emptyHistory
        case notARepository
    }

    private let scenario: Scenario
    private let delay: Duration

    public init(_ scenario: Scenario = .dirty, delay: Duration = .zero) {
        self.scenario = scenario
        self.delay = delay
    }

    public func repository(at location: WorkspaceLocation) async throws -> RepositoryRef {
        try await pause()
        guard scenario != .notARepository else { throw ErrorState.git(.notARepository) }
        return RepositoryRef(
            remoteID: GitFixtures.repository.remoteID,
            root: location.path,
            gitDir: location.path + "/.git"
        )
    }

    public func status(of repository: RepositoryRef) async throws -> RepositoryStatus {
        try await pause()
        switch scenario {
        case .dirty: return GitFixtures.dirtyStatus
        case .newFile: return GitFixtures.newFileStatus
        case .clean, .emptyHistory, .notARepository: return GitFixtures.cleanStatus
        }
    }

    public func diff(
        for file: ChangedFile,
        in repository: RepositoryRef,
        staged: Bool
    ) async throws -> FileDiff {
        try await pause()
        guard !file.isBinary else { throw ErrorState.git(.binaryDiff) }
        return GitDiffFixtures.diff(for: file)
    }

    public func diff(forUntracked path: String, in repository: RepositoryRef) async throws -> FileDiff {
        try await pause()
        return GitDiffFixtures.untracked(path)
    }

    public func history(
        of repository: RepositoryRef,
        before: CommitID?,
        limit: Int
    ) async throws -> [Commit] {
        try await pause()
        guard scenario != .emptyHistory else { return [] }
        guard let before else { return Array(GitFixtures.commits.prefix(limit)) }
        guard let index = GitFixtures.commits.firstIndex(where: { $0.id == before }) else { return [] }
        return Array(GitFixtures.commits.dropFirst(index + 1).prefix(limit))
    }

    public func diff(for commit: CommitID, in repository: RepositoryRef) async throws -> [FileDiff] {
        try await pause()
        return GitFixtures.staged.map(GitDiffFixtures.diff(for:))
    }

    private func pause() async throws {
        guard delay > .zero else { return }
        try await Task.sleep(for: delay)
    }
}
