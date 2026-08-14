#if canImport(UIKit)
import AnySSHCore
import SwiftUI

struct HistoryDetailView: View {
    let commit: Commit
    let repository: RepositoryRef
    let git: any GitService

    @Environment(\.dismiss) private var dismiss
    @State private var files: FilesState = .loading

    private enum FilesState {
        case loading
        case loaded([FileDiff])
        case failed(ErrorState)
    }

    var body: some View {
        List {
            message
            identity
            filesSection
        }
        .catalogListSurface()
        .navigationTitle("Commit")
        .accessibilityIdentifier(UIIdentifier.History.detail)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .accessibilityIdentifier(UIIdentifier.History.close)
            }
        }
        .task { await loadFiles() }
    }

    private var message: some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.Space.step2) {
                Text(commit.subject)
                    .font(Theme.Text.sectionHeader)
                    .foregroundStyle(Theme.text.primary)
                if !commit.body.isEmpty {
                    Text(commit.body)
                        .font(Theme.Text.body)
                        .foregroundStyle(Theme.text.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .catalogRowChrome()
        }
    }

    private var identity: some View {
        Section {
            VStack(spacing: Theme.Space.rowGap) {
                CopyableRow(
                    label: "SHA",
                    value: commit.id.rawValue,
                    monospaced: true,
                    accessibilityIdentifier: UIIdentifier.History.copySHA
                )
                CopyableRow(
                    label: "Author",
                    value: commit.authorName,
                    accessibilityIdentifier: UIIdentifier.History.copyAuthor
                )
                CopyableRow(
                    label: "Email",
                    value: commit.authorEmail,
                    monospaced: true,
                    accessibilityIdentifier: UIIdentifier.History.copyEmail
                )
                CopyableRow(
                    label: "Date",
                    value: commit.authoredAt.formatted(date: .abbreviated, time: .shortened),
                    accessibilityIdentifier: UIIdentifier.History.copyDate
                )
                if commit.parents.count > 1 {
                    Label("First-parent diff", systemImage: "arrow.triangle.branch")
                        .font(Theme.Text.caption)
                        .foregroundStyle(Theme.text.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier(UIIdentifier.History.firstParent)
                }
            }
            .catalogRowChrome()
        } header: {
            SectionLabel("Commit")
        }
    }

    @ViewBuilder
    private var filesSection: some View {
        Section {
            switch files {
            case .loading:
                LoadingView(.inline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Space.step4)
                    .catalogRowChrome()
            case .failed(let error):
                Text(error.copy.title)
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.text.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .catalogRowChrome()
            case .loaded(let diffs):
                fileRows(diffs)
            }
        } header: {
            SectionLabel("Files")
        }
    }

    @ViewBuilder
    private func fileRows(_ diffs: [FileDiff]) -> some View {
        if diffs.isEmpty {
            Text("This commit changed nothing.")
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .catalogRowChrome()
        } else {
            ForEach(Array(diffs.enumerated()), id: \.offset) { index, diff in
                FileDiffDisclosure(
                    file: diff.file,
                    identifier: UIIdentifier.History.file(index),
                    loaded: diff
                )
                .catalogRowChrome()
            }
        }
    }

    private func loadFiles() async {
        do {
            files = .loaded(try await git.diff(for: commit.id, in: repository))
        } catch let error as ErrorState {
            files = .failed(error)
        } catch {
            files = .failed(.git(.diffTruncated))
        }
    }
}
#endif
