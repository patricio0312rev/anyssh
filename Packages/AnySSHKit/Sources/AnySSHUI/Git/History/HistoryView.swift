#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct HistoryView: View {
    @State private var model: HistoryModel
    @State private var selected: Commit?

    private let service: any GitService
    private let repository: RepositoryRef

    public init(
        service: any GitService,
        repository: RepositoryRef,
        clock: any Clock = SystemClock(),
        selected: Commit? = nil
    ) {
        _model = State(
            wrappedValue: HistoryModel(service: service, repository: repository, clock: clock)
        )
        _selected = State(wrappedValue: selected)
        self.service = service
        self.repository = repository
    }

    public var body: some View {
        content
            .navigationTitle("History")
            .accessibilityIdentifier(UIIdentifier.History.screen)
            .task { await model.load() }
            .sheet(item: $selected) { commit in
                NavigationStack {
                    HistoryDetailView(commit: commit, repository: repository, git: service)
                }
                .presentationDragIndicator(.visible)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            LoadingView(.screen(label: "Loading history"))
                .background(Theme.surface.base)
                .accessibilityIdentifier(UIIdentifier.History.loading)
        case .empty:
            ErrorStateView(state: .git(.unbornBranch))
                .accessibilityIdentifier(UIIdentifier.History.empty)
        case .failed(let state):
            ErrorStateView(state: state) { Task { await model.load() } }
        case .loaded:
            list
        }
    }

    private var list: some View {
        List {
            ForEach(model.commits) { commit in
                Button {
                    selected = commit
                } label: {
                    HistoryRow(commit: commit, date: model.relativeDate(commit.authoredAt))
                }
                .buttonStyle(.plain)
                .catalogRowChrome()
                .onAppear {
                    guard commit.id == model.commits.last?.id else { return }
                    Task { await model.loadMore() }
                }
            }
            if model.isLoadingMore {
                LoadingView(.inline)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .catalogListSurface()
        .accessibilityIdentifier(UIIdentifier.History.list)
    }
}
#endif
