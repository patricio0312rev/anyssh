import AnySSHCore
import Testing

@testable import Highlighting

@Suite struct TokenCacheTests {
    @Test func aSecondRequestForTheSameShaIssuesZeroParses() async throws {
        let blob = try HighlightingFixtures.blob("sample.ts")
        let highlighter = TreeSitterHighlighter()

        let first = await highlighter.tokens(for: blob, language: .typescript, blobSha: "abc123")
        let afterFirst = await highlighter.parseCount

        let second = await highlighter.tokens(for: blob, language: .typescript, blobSha: "abc123")
        let afterSecond = await highlighter.parseCount

        #expect(afterFirst == 1)
        #expect(afterSecond == 1, "a cache hit must not parse")
        #expect(first == second)
    }

    @Test func aDifferentShaParsesAgain() async throws {
        let blob = try HighlightingFixtures.blob("sample.ts")
        let highlighter = TreeSitterHighlighter()

        _ = await highlighter.tokens(for: blob, language: .typescript, blobSha: "abc123")
        _ = await highlighter.tokens(for: blob, language: .typescript, blobSha: "def456")

        #expect(await highlighter.parseCount == 2)
    }

    @Test func concurrentRequestsForOneShaParseOnce() async throws {
        let blob = try HighlightingFixtures.blob("sample.ts")
        let highlighter = TreeSitterHighlighter()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<8 {
                group.addTask {
                    _ = await highlighter.tokens(
                        for: blob,
                        language: .typescript,
                        blobSha: "abc123"
                    )
                }
            }
        }

        #expect(await highlighter.parseCount == 1)
    }

    @Test func theUnkeyedPortIsNotCached() async throws {
        let blob = try HighlightingFixtures.blob("sample.ts")
        let highlighter = TreeSitterHighlighter()

        _ = await highlighter.tokens(for: blob, language: .typescript)
        _ = await highlighter.tokens(for: blob, language: .typescript)

        #expect(await highlighter.parseCount == 2)
    }

    @Test func aWorkerCompilesEachGrammarQueryOnce() async throws {
        let worker = HighlightWorker()
        let blob = try HighlightingFixtures.blob("sample.ts")

        _ = await worker.tokens(for: blob, grammar: .typescript)
        _ = await worker.tokens(for: blob, grammar: .typescript)
        #expect(await worker.compiledGrammars == 1)

        _ = await worker.tokens(for: try HighlightingFixtures.blob("sample.go"), grammar: .go)
        #expect(await worker.compiledGrammars == 2)
    }

    @Test func theCacheEvictsLeastRecentlyUsedOnceOverBudget() {
        var cache = TokenCache(spanLimit: 12)
        let entry = [LineTokens(spans: [TokenSpan(range: 0..<1, scope: .keyword)])]

        cache.insert(entry, for: "a")
        cache.insert(entry, for: "b")
        cache.insert(entry, for: "c")
        _ = cache.value(for: "a")
        cache.insert(entry, for: "d")
        cache.insert(entry, for: "e")
        cache.insert(entry, for: "f")
        cache.insert(entry, for: "g")

        #expect(cache.value(for: "b") == nil)
        #expect(cache.value(for: "g") != nil)
        #expect(cache.count <= 6)
    }

    @Test func anEntryLargerThanTheWholeBudgetIsNotCached() {
        var cache = TokenCache(spanLimit: 2)
        let big = (0..<10).map { _ in
            LineTokens(spans: [TokenSpan(range: 0..<1, scope: .string)])
        }

        cache.insert(big, for: "big")

        #expect(cache.value(for: "big") == nil)
        #expect(cache.count == 0)
    }
}
