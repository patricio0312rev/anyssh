#if canImport(UIKit)
import AnySSHCore
import SwiftUI

struct FileEntryRow: View {
    let entry: DirectoryEntry

    var body: some View {
        CatalogRow(
            title: entry.name,
            subtitle: entry.kind == .symlink ? "Symbolic link" : nil,
            titleLineLimit: 1,
            accessibilityIdentifier: UIIdentifier.Workspace.entry(entry.name),
            leading: { icon },
            trailing: { RowChevron() },
            footer: { EmptyView() }
        )
    }

    @ViewBuilder
    private var icon: some View {
        if entry.isDirectory {
            FileIconView(folderName: entry.name)
        } else {
            FileIconView(fileName: entry.name)
        }
    }
}
#endif
