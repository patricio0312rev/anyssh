import AnySSHCore
import Testing

@testable import Highlighting

@Suite struct HunkSlicingTests {
    private static let old = [
        LineTokens(spans: [TokenSpan(range: 0..<3, scope: .keyword)]),
        LineTokens(spans: [TokenSpan(range: 0..<3, scope: .comment)]),
        LineTokens(spans: [TokenSpan(range: 0..<3, scope: .string)]),
    ]

    private static let new = [
        LineTokens(spans: [TokenSpan(range: 0..<3, scope: .type)]),
        LineTokens(spans: [TokenSpan(range: 0..<3, scope: .number)]),
        LineTokens(spans: [TokenSpan(range: 0..<3, scope: .function)]),
    ]

    @Test func eachRowKindReadsTheSideItBelongsTo() {
        let hunk = DiffHunk(
            oldStart: 1,
            oldCount: 2,
            newStart: 1,
            newCount: 2,
            heading: "",
            lines: [
                DiffLine(kind: .context, text: "a", noNewlineAtEndOfFile: false),
                DiffLine(kind: .deletion, text: "b", noNewlineAtEndOfFile: false),
                DiffLine(kind: .addition, text: "c", noNewlineAtEndOfFile: false),
            ]
        )

        let rows = HunkSlicing.rows(for: hunk, old: Self.old, new: Self.new)

        #expect(rows.count == 3)
        #expect(rows[0].spans.first?.scope == .type, "context reads the new blob")
        #expect(rows[1].spans.first?.scope == .comment, "deletion reads old line 2")
        #expect(rows[2].spans.first?.scope == .number, "addition reads new line 2")
    }

    @Test func lineNumbersFollowTheHunkHeader() {
        let hunk = DiffHunk(
            oldStart: 3,
            oldCount: 1,
            newStart: 3,
            newCount: 1,
            heading: "",
            lines: [DiffLine(kind: .context, text: "c", noNewlineAtEndOfFile: false)]
        )

        let rows = HunkSlicing.rows(for: hunk, old: Self.old, new: Self.new)

        #expect(rows[0].spans.first?.scope == .function)
    }

    @Test func aRowOutsideTheBlobIsPlainRatherThanTheNeighbouringLine() {
        let hunk = DiffHunk(
            oldStart: 99,
            oldCount: 1,
            newStart: 99,
            newCount: 1,
            heading: "",
            lines: [DiffLine(kind: .deletion, text: "x", noNewlineAtEndOfFile: false)]
        )

        let rows = HunkSlicing.rows(for: hunk, old: Self.old, new: Self.new)

        #expect(rows.count == 1)
        #expect(rows[0].spans.isEmpty)
    }

    @Test func hunkTextIsNotStrippedASecondTime() {
        let hunk = DiffHunk(
            oldStart: 1,
            oldCount: 0,
            newStart: 1,
            newCount: 2,
            heading: "",
            lines: [
                DiffLine(kind: .addition, text: "    indented();", noNewlineAtEndOfFile: false),
                DiffLine(kind: .addition, text: "-dashLeading", noNewlineAtEndOfFile: false),
            ]
        )

        let text = HunkSlicing.text(of: hunk)

        #expect(text == "    indented();\n-dashLeading")
    }

    @Test func rawPatchLinesLoseExactlyOneMarkerColumn() {
        let raw = ["+    added();", "-    removed();", "     context();", "\\ No newline"]

        #expect(
            DiffMarker.strip(lines: raw) == [
                "    added();", "    removed();", "    context();", "\\ No newline",
            ])
        #expect(DiffMarker.strip("") == "")
    }
}
