#if canImport(UIKit)
import AnySSHCore
import SwiftUI

struct ChangedFileRow: View {
    let file: ChangedFile
    let identifier: String
    var isUntracked = false

    var body: some View {
        CatalogRow(
            title: name,
            subtitle: directory,
            subtitleMonospaced: true,
            subtitleLineLimit: 1,
            titleLineLimit: 1,
            accessibilityIdentifier: identifier
        ) {
            FileIconView(fileName: name)
        } trailing: {
            ChangedFileCounts(file: file, isUntracked: isUntracked)
        } footer: {
            EmptyView()
        }
    }

    private var path: String { file.newPath ?? file.oldPath ?? "" }

    private var name: String {
        (path as NSString).lastPathComponent
    }

    private var directory: String? {
        guard file.change.isRename, let oldPath = file.oldPath, let newPath = file.newPath else {
            let folder = (path as NSString).deletingLastPathComponent
            return folder.isEmpty ? nil : folder
        }
        return "\(oldPath) → \(newPath)"
    }
}

private struct ChangedFileCounts: View {
    let file: ChangedFile
    let isUntracked: Bool

    var body: some View {
        if isUntracked {
            Text("New")
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.status.online)
        } else if file.isBinary {
            Text("Binary")
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.tertiary)
        } else {
            HStack(spacing: Theme.Space.step2) {
                Text("+\(file.additions)").foregroundStyle(Theme.status.online)
                Text("-\(file.deletions)").foregroundStyle(Theme.status.error)
            }
            .font(Theme.Text.caption)
        }
    }
}

#Preview("ChangedFileRow") {
    ThemedRoot {
        VStack(spacing: Theme.Space.rowGap) {
            ChangedFileRow(
                file: ChangedFile(
                    oldPath: "Sources/App/Root.swift",
                    newPath: "Sources/App/Root.swift",
                    change: .modified,
                    isBinary: false,
                    additions: 24,
                    deletions: 7
                ),
                identifier: "preview.changes.modified"
            )
            ChangedFileRow(
                file: ChangedFile(
                    oldPath: nil,
                    newPath: "Resources/logo.png",
                    change: .added,
                    isBinary: true
                ),
                identifier: "preview.changes.binary"
            )
            ChangedFileRow(
                file: ChangedFile(oldPath: nil, newPath: "notes.md", change: .added, isBinary: false),
                identifier: "preview.changes.untracked",
                isUntracked: true
            )
        }
        .padding(Theme.Space.screenMargin)
    }
}
#endif
