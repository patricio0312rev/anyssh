#if canImport(UIKit)
import AnySSHCore
import SwiftUI

struct SnippetRow: View {
    let snippet: Snippet

    var body: some View {
        CatalogRow(
            title: snippet.label,
            subtitle: snippet.title.isEmpty ? nil : snippet.body,
            subtitleMonospaced: true,
            accessibilityIdentifier: SnippetIdentifier.row(snippet.id),
            leading: {
                RowIconTile(
                    systemImage: "chevron.left.forwardslash.chevron.right",
                    label: "Snippet"
                )
            },
            trailing: { EmptyView() },
            footer: { EmptyView() }
        )
    }
}

#Preview("SnippetRow") {
    ThemedRoot {
        List {
            SnippetRow(snippet: Snippet(title: "Tail the log", body: "tail -f /var/log/syslog"))
                .catalogRowChrome()
            SnippetRow(snippet: Snippet(title: "", body: "git status --short"))
                .catalogRowChrome()
        }
        .catalogListSurface()
    }
}
#endif
