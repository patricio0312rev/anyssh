import AnySSHCore
import Foundation

public enum GitFixtures {
    public static let root = "/Users/dev/src/anyssh"

    public static let location = WorkspaceLocation(path: root, provenance: .shellIntegration)

    public static let repository = RepositoryRef(
        remoteID: RemoteFixtures.workstation.id,
        root: root,
        gitDir: root + "/.git"
    )

    public static let staged: [ChangedFile] = [
        ChangedFile(
            oldPath: "Sources/AnySSHUI/Git/Changes/ChangesListView.swift",
            newPath: "Sources/AnySSHUI/Git/Changes/ChangesListView.swift",
            change: .modified,
            isBinary: false,
            additions: 34,
            deletions: 12
        ),
        ChangedFile(
            oldPath: "Sources/AnySSHUI/Git/DiffRenderer/DiffRow.swift",
            newPath: "Sources/AnySSHUI/Git/DiffRenderer/DiffRowModel.swift",
            change: .renamed(similarity: 92),
            isBinary: false,
            additions: 8,
            deletions: 3
        ),
    ]

    public static let unstaged: [ChangedFile] = [
        ChangedFile(
            oldPath: "Package.swift",
            newPath: "Package.swift",
            change: .modified,
            isBinary: false,
            additions: 2,
            deletions: 2
        ),
        ChangedFile(
            oldPath: "Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png",
            newPath: "Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png",
            change: .modified,
            isBinary: true
        ),
    ]

    public static let untracked = ["docs/plan-git-surfaces.md", "Scripts/screenshot-git.sh"]

    public static let dirtyStatus = RepositoryStatus(
        head: .branch("feat/git_surfaces"),
        upstream: UpstreamTracking(name: "origin/feat/git_surfaces", ahead: 2, behind: 1),
        staged: staged,
        unstaged: unstaged,
        untracked: untracked,
        unmerged: []
    )

    public static let newFileStatus = RepositoryStatus(
        head: .branch("feat/git_surfaces"),
        upstream: UpstreamTracking(name: "origin/feat/git_surfaces", ahead: 2, behind: 1),
        staged: [GitDiffFixtures.newFile(at: "docs/plan-git-surfaces.md")],
        unstaged: [],
        untracked: [],
        unmerged: []
    )

    public static let cleanStatus = RepositoryStatus(
        head: .branch("main"),
        upstream: UpstreamTracking(name: "origin/main", ahead: 0, behind: 0),
        staged: [],
        unstaged: [],
        untracked: [],
        unmerged: []
    )

    public static let commits: [Commit] = subjects.enumerated().map { index, entry in
        Commit(
            id: CommitID(rawValue: shas[index % shas.count]),
            parents: index == 2 ? parents : [CommitID(rawValue: shas[(index + 1) % shas.count])],
            authorName: authors[index % authors.count],
            authorEmail: emails[index % emails.count],
            authoredAt: Date(timeIntervalSinceNow: -Double(index + 1) * 9_000),
            subject: entry.0,
            body: entry.1,
            references: index == 0 ? ["HEAD -> feat/git_surfaces", "origin/main"] : []
        )
    }

    private static let shas = [
        "8f3c1d9a2b4e6f70a1c3d5e7f9012345678abcd0",
        "c47b2e81a9d05f3c6b8e0d2a4f6180935bcde12f",
        "1a9e5c73d08b4f26a1c9e7b3d5f80264ace13579",
        "b62d0f48e15a7c93d2b6f8a04c7e1935bdf24680",
        "5d81c3a70f92e4b6a8d0c2f4e68013579bdf2468",
        "e70f2b95c8a13d64f2b0d8e6a4c20197531fdb86",
    ]

    private static let parents = [
        CommitID(rawValue: "1a9e5c73d08b4f26a1c9e7b3d5f80264ace13579"),
        CommitID(rawValue: "b62d0f48e15a7c93d2b6f8a04c7e1935bdf24680"),
    ]

    private static let authors = ["Patricio Marroquin", "Ada Lovelace", "Grace Hopper"]

    private static let emails = ["patricio@anyssh.app", "ada@anyssh.app", "grace@anyssh.app"]

    private static let subjects: [(String, String)] = [
        ("feat: render diffs on the Monokai canvas", "The diff surface now takes its tints from Theme.Code."),
        ("fix: keep the changes header off the card", ""),
        ("Merge branch 'main' into feat/git_surfaces", "Resolves the DiffRenderer conflict."),
        ("refactor: fold three disclosures into one", "Untracked, unstaged and commit files share a row."),
        ("test: cover collapsed hunks", ""),
        ("chore: bump the pinned libssh2 slice", ""),
    ]
}
