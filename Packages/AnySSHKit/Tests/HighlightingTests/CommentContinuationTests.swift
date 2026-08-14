import AnySSHCore
import Testing

@testable import Highlighting

@Suite struct CommentContinuationTests {
    private static let fixture = "comment-continuation.ts"

    private static func hunk() -> DiffHunk {
        DiffHunk(
            oldStart: 4,
            oldCount: 3,
            newStart: 4,
            newCount: 4,
            heading: "",
            lines: [
                DiffLine(
                    kind: .context,
                    text: #"const legacy = { retries: 3, label: "old" };"#,
                    noNewlineAtEndOfFile: false
                ),
                DiffLine(kind: .context, text: "", noNewlineAtEndOfFile: false),
                DiffLine(kind: .context, text: "*/", noNewlineAtEndOfFile: false),
                DiffLine(
                    kind: .addition,
                    text: "export const retries = 3;",
                    noNewlineAtEndOfFile: false
                ),
            ]
        )
    }

    @Test func aHunkInsideABlockCommentIsCommentWhenSlicedFromTheBlob() async throws {
        let blob = try HighlightingFixtures.blob(Self.fixture)
        let highlighter = TreeSitterHighlighter()
        let sides = DiffSides(
            old: BlobSide(sha: "old-sha", text: blob),
            new: BlobSide(sha: "new-sha", text: blob)
        )

        let result = await highlighter.highlight(
            hunk: Self.hunk(),
            language: .typescript,
            sides: sides
        )

        #expect(result.tier == .wholeBlob)
        #expect(result.rows.count == 4)
        #expect(result.rows[0].spans.map(\.scope) == [.comment])
        #expect(result.rows[3].spans.first?.scope == .keyword)
    }

    @Test func theSameHunkParsedAloneIsNotComment() async {
        let highlighter = TreeSitterHighlighter()
        let hunk = Self.hunk()

        let result = await highlighter.highlight(
            hunk: hunk,
            language: .typescript,
            sides: DiffSides(old: nil, new: nil)
        )

        #expect(result.tier == .hunkOnly)
        #expect(result.rows.count == 4)
        #expect(result.rows[0].spans.first?.scope == .keyword)
        #expect(result.rows[0].spans.contains { $0.scope == .comment } == false)
    }
}
