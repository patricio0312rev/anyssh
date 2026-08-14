import AnySSHCore
import Foundation
import Testing

@testable import AnySSHCore

@Suite
struct RecentDirectoriesMergeTests {
    @Test func pathSeenByTwoAgentsAppearsOnceWithSourcesMostRecentFirst() {
        let claude = RecentDirectorySighting(
            path: "/Users/dev/src/anyssh",
            source: .claude,
            lastUsed: Date(timeIntervalSince1970: 100)
        )
        let codex = RecentDirectorySighting(
            path: "/Users/dev/src/anyssh",
            source: .codex,
            lastUsed: Date(timeIntervalSince1970: 200)
        )
        let portfolio = RecentDirectorySighting(
            path: "/Users/dev/src/portfolio",
            source: .opencode,
            lastUsed: Date(timeIntervalSince1970: 150)
        )
        let list = RecentDirectoriesMerger.merge([claude, codex, portfolio], limit: 40)
        #expect(list.count == 2)
        #expect(list[0].path == "/Users/dev/src/anyssh")
        #expect(list[0].sources == [.codex, .claude])
        #expect(list[0].lastUsed.timeIntervalSince1970 == 200)
        #expect(list[1].path == "/Users/dev/src/portfolio")
        #expect(list[1].sources == [.opencode])
    }

    @Test func orderingIsByMaximumInstantAcrossSources() {
        let olderClaude = RecentDirectorySighting(
            path: "/a",
            source: .claude,
            lastUsed: Date(timeIntervalSince1970: 10)
        )
        let newerCursor = RecentDirectorySighting(
            path: "/b",
            source: .cursor,
            lastUsed: Date(timeIntervalSince1970: 50)
        )
        let middleOpenCode = RecentDirectorySighting(
            path: "/a",
            source: .opencode,
            lastUsed: Date(timeIntervalSince1970: 40)
        )
        let list = RecentDirectoriesMerger.merge(
            [olderClaude, newerCursor, middleOpenCode],
            limit: 10
        )
        #expect(list.map(\.path) == ["/b", "/a"])
        #expect(list[1].sources == [.opencode, .claude])
        #expect(list[1].lastUsed.timeIntervalSince1970 == 40)
    }

    @Test func trailingSlashAndEmptyPathsNormalize() {
        let a = RecentDirectorySighting(
            path: "/Users/dev/src/anyssh/",
            source: .claude,
            lastUsed: Date(timeIntervalSince1970: 1)
        )
        let b = RecentDirectorySighting(
            path: "/Users/dev/src/anyssh",
            source: .codex,
            lastUsed: Date(timeIntervalSince1970: 2)
        )
        let empty = RecentDirectorySighting(
            path: "   ",
            source: .cursor,
            lastUsed: Date(timeIntervalSince1970: 3)
        )
        let list = RecentDirectoriesMerger.merge([a, b, empty], limit: 40)
        #expect(list.count == 1)
        #expect(list[0].path == "/Users/dev/src/anyssh")
        #expect(list[0].sources == [.codex, .claude])
    }

    @Test func limitZeroReturnsEmpty() {
        let sighting = RecentDirectorySighting(
            path: "/x",
            source: .claude,
            lastUsed: Date(timeIntervalSince1970: 1)
        )
        #expect(RecentDirectoriesMerger.merge([sighting], limit: 0).isEmpty)
    }

    @Test func rootAndTempPathsAreDropped() {
        let noise = [
            RecentDirectorySighting(path: "/", source: .opencode, lastUsed: Date(timeIntervalSince1970: 9)),
            RecentDirectorySighting(path: "/tmp", source: .codex, lastUsed: Date(timeIntervalSince1970: 8)),
            RecentDirectorySighting(
                path: "/Users/dev/src/anyssh",
                source: .claude,
                lastUsed: Date(timeIntervalSince1970: 1)
            ),
        ]
        let list = RecentDirectoriesMerger.merge(noise, limit: 40)
        #expect(list.map(\.path) == ["/Users/dev/src/anyssh"])
    }

    @Test func basenameHandlesRootAndNested() {
        #expect(RecentDirectory(path: "/", sources: [.claude], lastUsed: .distantPast).basename == "/")
        #expect(
            RecentDirectory(
                path: "/Users/dev/src/anyssh",
                sources: [.claude],
                lastUsed: .distantPast
            ).basename == "anyssh"
        )
    }
}
