import AnySSHCore
import Foundation
import Observation

@MainActor
@Observable
final class HistoryModel {
    enum State {
        case loading
        case loaded([Commit])
        case empty
        case failed(ErrorState)
    }

    private let service: any GitService
    private let repository: RepositoryRef
    private let pageSize: Int
    private let clock: any Clock

    private(set) var state: State = .loading
    private(set) var isLoadingMore = false

    init(
        service: any GitService,
        repository: RepositoryRef,
        clock: any Clock = SystemClock(),
        pageSize: Int = 30
    ) {
        self.service = service
        self.repository = repository
        self.clock = clock
        self.pageSize = pageSize
    }

    var commits: [Commit] {
        guard case .loaded(let commits) = state else { return [] }
        return commits
    }

    func load() async {
        do {
            let commits = try await service.history(of: repository, before: nil, limit: pageSize)
            state = commits.isEmpty ? .empty : .loaded(commits)
        } catch {
            state = .failed(error as? ErrorState ?? .git(.notARepository))
        }
    }

    func loadMore() async {
        guard !isLoadingMore, let last = commits.last else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let next = try await service.history(of: repository, before: last.id, limit: pageSize)
            if !next.isEmpty { state = .loaded(commits + next) }
        } catch {
            state = .failed(error as? ErrorState ?? .git(.notARepository))
        }
    }

    func relativeDate(_ date: Date) -> String {
        let style = Date.AnchoredRelativeFormatStyle(
            anchor: date,
            presentation: .named,
            unitsStyle: .abbreviated
        )
        return style.format(clock.now)
    }
}
