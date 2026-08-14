import AnySSHCore

public enum GitDiffFixtures {
    public static func diff(for file: ChangedFile) -> FileDiff {
        guard !file.isBinary else {
            return FileDiff(file: file, hunks: [], isBinary: true, truncated: false, lossyDecode: false)
        }
        guard file.change != .added else { return added(file) }
        return FileDiff(
            file: file,
            hunks: [header, body],
            isBinary: false,
            truncated: false,
            lossyDecode: false
        )
    }

    public static func untracked(_ path: String) -> FileDiff {
        added(newFile(at: path))
    }

    public static func newFile(at path: String) -> ChangedFile {
        ChangedFile(
            oldPath: nil,
            newPath: path,
            change: .added,
            isBinary: false,
            additions: additions.count,
            deletions: 0
        )
    }

    private static func added(_ file: ChangedFile) -> FileDiff {
        FileDiff(
            file: file,
            hunks: [
                DiffHunk(
                    oldStart: 0,
                    oldCount: 0,
                    newStart: 1,
                    newCount: additions.count,
                    heading: "@@ -0,0 +1,\(additions.count) @@",
                    lines: additions.map { line(.addition, $0) }
                )
            ],
            isBinary: false,
            truncated: false,
            lossyDecode: false
        )
    }

    private static let header = DiffHunk(
        oldStart: 1,
        oldCount: 4,
        newStart: 1,
        newCount: 5,
        heading: "@@ -1,4 +1,5 @@ import SwiftUI",
        lines: [
            line(.context, "#if canImport(UIKit)"),
            line(.context, "import AnySSHCore"),
            line(.addition, "import GitClient"),
            line(.context, "import SwiftUI"),
            line(.context, ""),
        ]
    )

    private static let body = DiffHunk(
        oldStart: 41,
        oldCount: 7,
        newStart: 42,
        newCount: 9,
        heading: "@@ -41,7 +42,9 @@ private func changes(_ status: RepositoryStatus)",
        lines: [
            line(.context, "    private func fileList(_ status: RepositoryStatus) -> some View {"),
            line(.deletion, "        List(status.unstaged, id: \\.self) { file in"),
            line(.deletion, "            ChangedFileRow(file: file)"),
            line(.addition, "        VStack(spacing: 0) {"),
            line(.addition, "            ChangesBranchHeader(location: model.location, status: status)"),
            line(.addition, "            List {"),
            line(
                .addition, "                fileSection(\"Staged\", files: status.staged, prefix: \"staged\")"
            ),
            line(.context, "            }"),
            line(.context, "        }"),
        ]
    )

    private static let additions = [
        "# Git surfaces",
        "",
        "Changes, history and the diff renderer.",
        "",
        "## Rendering",
        "",
        "Every hunk keeps the numbers it has and reserves nothing for the ones it lacks.",
    ]

    private static func line(_ kind: DiffLineKind, _ text: String) -> DiffLine {
        DiffLine(kind: kind, text: text, noNewlineAtEndOfFile: false)
    }
}
