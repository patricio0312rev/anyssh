#if canImport(UIKit)
import AnySSHCore
import AnySSHMocks
import Foundation
import Testing

@testable import AnySSHUI

private struct FixedClock: Clock {
    let now: Date
}

@MainActor
@Suite struct HistoryModelTests {
    private func model(_ scenario: MockGitService.Scenario, pageSize: Int = 30) -> HistoryModel {
        HistoryModel(
            service: MockGitService(scenario),
            repository: GitFixtures.repository,
            clock: FixedClock(now: Date(timeIntervalSince1970: 1_770_000_000)),
            pageSize: pageSize
        )
    }

    @Test func aRepositoryWithoutCommitsReportsEmpty() async {
        let model = model(.emptyHistory)

        await model.load()

        guard case .empty = model.state else {
            Issue.record("expected empty, got \(model.state)")
            return
        }
    }

    @Test func loadingMoreAppendsTheNextPage() async {
        let model = model(.dirty, pageSize: 2)

        await model.load()
        let firstPage = model.commits
        await model.loadMore()

        #expect(firstPage.count == 2)
        #expect(model.commits.count == 4)
        #expect(model.commits.prefix(2).map(\.id) == firstPage.map(\.id))
    }

    @Test func loadingMorePastTheLastPageKeepsWhatIsThere() async {
        let model = model(.dirty)

        await model.load()
        let all = model.commits
        await model.loadMore()

        #expect(model.commits.map(\.id) == all.map(\.id))
    }

    @Test func aCommitInThePastReadsAsPast() {
        let model = model(.dirty)
        let anchor = Date(timeIntervalSince1970: 1_770_000_000)

        let text = model.relativeDate(anchor.addingTimeInterval(-9_000))

        #expect(text.contains("ago"))
    }
}
#endif
