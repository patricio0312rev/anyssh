#if canImport(UIKit)
import AnySSHCore
import Testing

@testable import AnySSHUI

@Suite struct DiffRowExpansionTests {
    private var diff: FileDiff {
        let lines =
            (0..<40).map { DiffLine(kind: .context, text: "context \($0)", noNewlineAtEndOfFile: false) }
            + [DiffLine(kind: .addition, text: "added", noNewlineAtEndOfFile: false)]
        return FileDiff(
            file: ChangedFile(oldPath: nil, newPath: "big.swift", change: .modified, isBinary: false),
            hunks: [
                DiffHunk(
                    oldStart: 1, oldCount: 40, newStart: 1, newCount: 41, heading: "",
                    lines: lines
                )
            ],
            isBinary: false,
            truncated: false,
            lossyDecode: false
        )
    }

    @Test func aLongHunkIsCollapsedUntilAsked() {
        let collapsed = DiffRowModel(diff: diff)

        #expect(collapsed.rows.contains { $0.kind == .collapsed })
    }

    @Test func expandingShowsEveryLine() {
        let collapsed = DiffRowModel(diff: diff)
        let expanded = DiffRowModel(diff: diff, expandAll: true)

        #expect(expanded.rows.count > collapsed.rows.count)
        #expect(!expanded.rows.contains { $0.kind == .collapsed })
    }

    @Test func theChangedLineSurvivesBothStates() {
        for model in [DiffRowModel(diff: diff), DiffRowModel(diff: diff, expandAll: true)] {
            #expect(model.rows.contains { $0.kind == .addition && $0.text == "added" })
        }
    }
}
#endif
