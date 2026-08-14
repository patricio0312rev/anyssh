#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct ChangesListView: View {
    @State private var model: ChangesListModel

    private let expandsFirstFile: Bool

    public init(location: WorkspaceLocation, git: any GitService, expandsFirstFile: Bool = false) {
        _model = State(wrappedValue: ChangesListModel(location: location, git: git))
        self.expandsFirstFile = expandsFirstFile
    }

    public var body: some View {
        content
            .toolbar { historyItem }
            .task { await model.load() }
    }

    @ToolbarContentBuilder
    private var historyItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if let repository = model.repository {
                NavigationLink {
                    HistoryView(service: model.gitService, repository: repository)
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .accessibilityLabel("History")
                .accessibilityIdentifier(UIIdentifier.Changes.openHistory)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            LoadingView(.screen(label: "Loading changes"))
                .background(Theme.surface.base)
                .accessibilityIdentifier(UIIdentifier.Changes.loading)
        case .failure(let state):
            ErrorStateView(state: state) { Task { await model.load() } }
        case .loaded(let status):
            changes(status)
        }
    }

    @ViewBuilder
    private func changes(_ status: RepositoryStatus) -> some View {
        if status.staged.isEmpty && status.unstaged.isEmpty && status.untracked.isEmpty {
            VStack(spacing: 0) {
                ChangesBranchHeader(location: model.location, status: status)
                Text("Working tree clean")
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.tertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityIdentifier(UIIdentifier.Changes.clean)
            }
            .background(Theme.surface.base)
        } else {
            fileList(status)
        }
    }

    private func fileList(_ status: RepositoryStatus) -> some View {
        VStack(spacing: 0) {
            ChangesBranchHeader(location: model.location, status: status)
            List {
                if !status.staged.isEmpty {
                    fileSection("Staged", files: status.staged, prefix: "staged")
                }
                if !status.unstaged.isEmpty {
                    fileSection("Unstaged", files: status.unstaged, prefix: "unstaged")
                }
                if !status.untracked.isEmpty { untrackedSection(status.untracked) }
            }
            .catalogListSurface()
            .accessibilityIdentifier(UIIdentifier.Changes.list)
        }
        .background(Theme.surface.base)
    }

    private func fileSection(_ title: String, files: [ChangedFile], prefix: String) -> some View {
        Section {
            ForEach(Array(files.enumerated()), id: \.offset) { index, file in
                FileDiffDisclosure(
                    file: file,
                    identifier: UIIdentifier.Changes.file(prefix, index),
                    load: { [git = model.gitService, repository = model.repository] in
                        guard let repository else { throw ErrorState.git(.notARepository) }
                        return try await git.diff(for: file, in: repository, staged: prefix == "staged")
                    },
                    startsExpanded: expandsFirstFile && index == 0 && prefix == "staged"
                )
                .catalogRowChrome()
            }
        } header: {
            SectionLabel(title)
        }
    }

    private func untrackedSection(_ paths: [String]) -> some View {
        Section {
            ForEach(Array(paths.enumerated()), id: \.offset) { index, path in
                FileDiffDisclosure(
                    file: ChangedFile(oldPath: nil, newPath: path, change: .added, isBinary: false),
                    identifier: UIIdentifier.Changes.file("untracked", index),
                    isUntracked: true,
                    load: { [git = model.gitService, repository = model.repository] in
                        guard let repository else { throw ErrorState.git(.notARepository) }
                        return try await git.diff(forUntracked: path, in: repository)
                    }
                )
                .catalogRowChrome()
            }
        } header: {
            SectionLabel("Untracked")
        }
    }
}
#endif
