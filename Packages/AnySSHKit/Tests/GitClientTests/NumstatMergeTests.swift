import AnySSHCore
import Testing

@testable import GitClient

@Suite struct NumstatMergeTests {
    private let modified = ChangedFile(
        oldPath: nil, newPath: "Sources/App.swift", change: .modified, isBinary: false
    )

    @Test func countsReachTheFileThatStatusListed() {
        let counted = ChangedFile(
            oldPath: "Sources/App.swift", newPath: "Sources/App.swift", change: .modified,
            isBinary: false, additions: 12, deletions: 3
        )

        let merged = NumstatMerge.apply([counted], to: [modified])

        #expect(merged.first?.additions == 12)
        #expect(merged.first?.deletions == 3)
    }

    @Test func aFileWithNoCountsSurvives() {
        let merged = NumstatMerge.apply([], to: [modified])

        #expect(merged.count == 1)
        #expect(merged.first?.newPath == "Sources/App.swift")
    }

    @Test func aRenameIsMatchedFromEitherSide() {
        let renamed = ChangedFile(
            oldPath: "old/Name.swift", newPath: "new/Name.swift",
            change: .renamed(similarity: 96), isBinary: false
        )
        let counted = ChangedFile(
            oldPath: "old/Name.swift", newPath: "new/Name.swift", change: .modified,
            isBinary: false, additions: 4, deletions: 2
        )

        let merged = NumstatMerge.apply([counted], to: [renamed])

        #expect(merged.first?.additions == 4)
        #expect(merged.first?.change.isRename == true)
    }

    @Test func binaryStaysBinary() {
        let counted = ChangedFile(
            oldPath: "logo.png", newPath: "logo.png", change: .modified, isBinary: true
        )

        let merged = NumstatMerge.apply(
            [counted],
            to: [ChangedFile(oldPath: nil, newPath: "logo.png", change: .modified, isBinary: false)]
        )

        #expect(merged.first?.isBinary == true)
    }

    @Test func theStatusKeepsItsOwnVerdict() {
        let counted = ChangedFile(
            oldPath: "notes.md", newPath: "notes.md", change: .deleted, isBinary: false,
            additions: 0, deletions: 40
        )

        let merged = NumstatMerge.apply(
            [counted],
            to: [ChangedFile(oldPath: nil, newPath: "notes.md", change: .modified, isBinary: false)]
        )

        #expect(merged.first?.change == .modified)
        #expect(merged.first?.deletions == 40)
    }
}
