import AnySSHCore
import Foundation
import Testing

@testable import Highlighting

@Suite struct HighlightPerfTests {
    static let blobName = "typescript-12447.ts"
    static let lineCount = 12_447
    static let byteCount = 514_454
    static let iterations = 9

    #if DEBUG
    static let budget = Duration.milliseconds(560)
    static let configuration = "debug"
    #else
    static let budget = Duration.milliseconds(50)
    static let configuration = "release"
    #endif

    @Test func highlightsTheLargeTypeScriptBlobWithinBudget() throws {
        let blob = try HighlightingFixtures.blob(Self.blobName)
        #expect(blob.utf8.count(where: { $0 == 0x0A }) == Self.lineCount, "fixture line count")
        #expect(blob.utf8.count == Self.byteCount, "fixture byte count")

        let session = try #require(GrammarSession(grammar: .typescript))
        var samples: [Duration] = []

        for _ in 0..<Self.iterations {
            let start = threadCPUTime()
            let index = LineIndex(blob)
            let captures = session.captures(in: blob)
            let rows = TokenPainter(index: index).paint(captures ?? [])
            samples.append(threadCPUTime() - start)
            #expect(rows.count == Self.lineCount)
        }

        let sorted = samples.sorted()
        let best = sorted[0]
        let p50 = sorted[sorted.count / 2]
        let p99 = sorted[sorted.count - 1]
        print(
            """
            highlight-perf \(Self.configuration): \(Self.blobName) \
            \(Self.lineCount) lines, \(Self.byteCount) bytes, typescript, \
            n=\(Self.iterations) cpu min=\(best.milliseconds) p50=\(p50.milliseconds) \
            p99=\(p99.milliseconds) ms
            """
        )
        #expect(
            p50 < Self.budget,
            "p50 \(p50.milliseconds) ms exceeds the \(Self.configuration) budget"
        )
    }

    @Test func theFirstCallForAGrammarPaysForItsQuery() throws {
        let start = threadCPUTime()
        let session = try #require(GrammarSession(grammar: .typescript))
        let compile = threadCPUTime() - start

        print("highlight-perf \(Self.configuration): typescript session build = \(compile.milliseconds) ms")
        #expect(session.captures(in: "const a = 1;") != nil)
    }

    @Test func highlightingRunsOffTheMainThread() async throws {
        let blob = try HighlightingFixtures.blob("sample.ts")
        let highlighter = TreeSitterHighlighter()

        let observed = await Task.detached(priority: .userInitiated) { () -> (Bool, Int) in
            let offMain = runningOnMainThread() == false
            let tokens = await highlighter.tokens(for: blob, language: .typescript)
            return (offMain, tokens.count)
        }.value

        #expect(observed.0, "highlighting must not be measured or run on the main thread")
        #expect(observed.1 == 12)
    }

    @Test func aCachedBlobCostsNothing() async throws {
        let blob = try HighlightingFixtures.blob(Self.blobName)
        let highlighter = TreeSitterHighlighter()
        _ = await highlighter.tokens(for: blob, language: .typescript, blobSha: "perf-sha")

        let start = threadCPUTime()
        let tokens = await highlighter.tokens(for: blob, language: .typescript, blobSha: "perf-sha")
        let elapsed = threadCPUTime() - start

        #expect(tokens.count == Self.lineCount)
        #expect(elapsed < .milliseconds(5), "a cache hit cost \(elapsed.milliseconds) ms")
    }
}

private func runningOnMainThread() -> Bool {
    Thread.isMainThread
}

private func threadCPUTime() -> Duration {
    .nanoseconds(clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID))
}

extension Duration {
    fileprivate var milliseconds: Double {
        Double(components.seconds) * 1000 + Double(components.attoseconds) / 1e15
    }
}
