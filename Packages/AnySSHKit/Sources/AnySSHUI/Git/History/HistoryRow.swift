import AnySSHCore
import SwiftUI

struct HistoryRow: View {
    let commit: Commit
    let date: String

    var body: some View {
        CatalogRow(
            title: commit.subject,
            subtitle: commit.authorName,
            detail: detail,
            layout: .stacked,
            accessibilityIdentifier: UIIdentifier.History.row(commit.id.rawValue)
        )
    }

    private var detail: String {
        [
            String(commit.id.rawValue.prefix(7)),
            date,
            commit.references.joined(separator: Theme.metaSeparator),
        ]
        .filter { !$0.isEmpty }
        .joined(separator: Theme.metaSeparator)
    }
}

#Preview("HistoryRow") {
    ThemedRoot {
        SurfaceCard {
            HistoryRow(
                commit: Commit(
                    id: CommitID(rawValue: "8f3c1d9a2b4e6f70a1c3d5e7f9012345"),
                    parents: [],
                    authorName: "Ada Lovelace",
                    authorEmail: "ada@anyssh.app",
                    authoredAt: .now,
                    subject: "feat: render diffs on the Monokai canvas",
                    body: "",
                    references: ["HEAD -> main"]
                ),
                date: "2 hr ago"
            )
        }
        .padding(Theme.Space.screenMargin)
    }
}
