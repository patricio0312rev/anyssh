import AnySSHCore
import Foundation

public enum GitFixtures {
    public static let root = "/home/dev/src/api"

    public static let location = WorkspaceLocation(path: root, provenance: .shellIntegration)

    public static let repository = RepositoryRef(
        remoteID: RemoteFixtures.workstation.id,
        root: root,
        gitDir: root + "/.git"
    )

    public static let staged: [ChangedFile] = [
        ChangedFile(
            oldPath: "Sources/API/Routes/SessionRoutes.swift",
            newPath: "Sources/API/Routes/SessionRoutes.swift",
            change: .modified,
            isBinary: false,
            additions: 34,
            deletions: 12
        ),
        ChangedFile(
            oldPath: "Sources/API/Models/UserRow.swift",
            newPath: "Sources/API/Models/AccountRow.swift",
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

    public static let untracked = ["docs/plan-session-routes.md", "Scripts/seed-db.sh"]

    public static let dirtyStatus = RepositoryStatus(
        head: .branch("feat/session_routes"),
        upstream: UpstreamTracking(name: "origin/feat/session_routes", ahead: 2, behind: 1),
        staged: staged,
        unstaged: unstaged,
        untracked: untracked,
        unmerged: []
    )

    public static let newFileStatus = RepositoryStatus(
        head: .branch("feat/session_routes"),
        upstream: UpstreamTracking(name: "origin/feat/session_routes", ahead: 2, behind: 1),
        staged: [GitDiffFixtures.newFile(at: "docs/plan-session-routes.md")],
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
            references: index == 0 ? ["HEAD -> feat/session_routes", "origin/main"] : []
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

    private static let authors = ["Ada Lovelace", "Grace Hopper", "Alan Turing"]

    private static let emails = ["ada@example.com", "grace@example.com", "alan@example.com"]

    private static let subjects: [(String, String)] = [
        ("feat: paginate the session routes", "Cursor pagination replaces the offset scan."),
        ("fix: return 404 instead of an empty body", ""),
        ("Merge branch 'main' into feat/session_routes", "Resolves the AccountRow conflict."),
        (
            "refactor: fold three handlers into one router",
            "Session, account and token routes share a builder."
        ),
        ("test: cover the expired token path", ""),
        ("chore: bump the pinned postgres driver", ""),
    ]
}
