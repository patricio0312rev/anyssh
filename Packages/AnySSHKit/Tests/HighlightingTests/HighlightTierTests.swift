import AnySSHCore
import Testing

@testable import Highlighting

@Suite struct HighlightTierTests {
    private static func hunk() -> DiffHunk {
        DiffHunk(
            oldStart: 7,
            oldCount: 1,
            newStart: 7,
            newCount: 2,
            heading: "",
            lines: [
                DiffLine(kind: .context, text: "export const retries = 3;", noNewlineAtEndOfFile: false),
                DiffLine(kind: .addition, text: "export const delay = 0.5;", noNewlineAtEndOfFile: false),
            ]
        )
    }

    private static func sides(_ blob: String) -> DiffSides {
        DiffSides(old: BlobSide(sha: "old", text: blob), new: BlobSide(sha: "new", text: blob))
    }

    @Test func theThreeTiersProduceThreeDistinctResults() async throws {
        let blob = try HighlightingFixtures.blob("comment-continuation.ts")
        let highlighter = TreeSitterHighlighter()
        let hunk = Self.hunk()

        let tierZero = await highlighter.highlight(
            hunk: hunk,
            language: .plainText,
            sides: Self.sides(blob)
        )
        let tierOne = await highlighter.highlight(
            hunk: hunk,
            language: .typescript,
            sides: Self.sides(blob)
        )
        let tierTwo = await highlighter.highlight(
            hunk: hunk,
            language: .typescript,
            sides: DiffSides(old: nil, new: nil)
        )

        #expect(tierZero.tier == .rowTintOnly)
        #expect(tierOne.tier == .wholeBlob)
        #expect(tierTwo.tier == .hunkOnly)

        #expect(tierZero.rows.allSatisfy { $0.spans.isEmpty })
        #expect(tierOne.rows != tierZero.rows)
        #expect(tierTwo.rows != tierZero.rows)
        #expect(Set([tierZero, tierOne, tierTwo]).count == 3)
        #expect(tierOne.rows.count == hunk.lines.count)
        #expect(tierTwo.rows.count == hunk.lines.count)
    }

    @Test func aBlobOverTheCapFallsBackToTierTwo() throws {
        let oversized = String(repeating: "const x = 1;\n", count: 30_000)
        #expect(oversized.utf8.count > HighlightPolicy.blobByteCap)

        let tier = HighlightPolicy.tier(
            for: Self.hunk(),
            sides: DiffSides(old: nil, new: BlobSide(sha: "new", text: oversized)),
            language: .typescript
        )

        #expect(tier == .hunkOnly)
    }

    @Test func anAllAdditionHunkNeedsOnlyTheNewSide() async throws {
        let blob = try HighlightingFixtures.blob("sample.ts")
        let hunk = DiffHunk(
            oldStart: 0,
            oldCount: 0,
            newStart: 1,
            newCount: 2,
            heading: "",
            lines: [
                DiffLine(kind: .addition, text: "export const a = 1;", noNewlineAtEndOfFile: false),
                DiffLine(kind: .addition, text: "export const b = 2;", noNewlineAtEndOfFile: false),
            ]
        )

        let needed = HighlightPolicy.neededSides(for: hunk)
        #expect(needed.old == false)
        #expect(needed.new)

        let sides = DiffSides(old: nil, new: BlobSide(sha: "new", text: blob))
        let result = await TreeSitterHighlighter().highlight(
            hunk: hunk,
            language: .typescript,
            sides: sides
        )

        #expect(result.tier == .wholeBlob, "a missing old side must not demote an all-add hunk")
    }

    @Test func aLanguageWithNoGrammarStaysAtTierZero() {
        let tier = HighlightPolicy.tier(
            for: Self.hunk(),
            sides: Self.sides("anything"),
            language: .plainText
        )

        #expect(tier == .rowTintOnly)
    }
}
