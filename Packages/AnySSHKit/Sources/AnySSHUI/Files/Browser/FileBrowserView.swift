#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct FileBrowserView: View {
    @State private var model: FileBrowserModel
    @State private var opened: OpenedFile?
    @Environment(\.syntaxHighlighter) private var highlighter

    private struct OpenedFile: Identifiable, Hashable {
        let path: String
        let name: String
        var id: String { path }
    }

    public init(root: String, browser: any RemoteFileBrowser) {
        _model = State(wrappedValue: FileBrowserModel(root: root, browser: browser))
    }

    public var body: some View {
        ZStack {
            directory
                .offset(x: opened == nil ? 0 : -FileBrowserMetrics.parallax)
                .opacity(opened == nil ? 1 : 0)
            if let opened {
                FilePreviewView(
                    path: opened.path,
                    name: opened.name,
                    browser: model.browser,
                    highlighter: highlighter,
                    onClose: close
                )
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }
        }
        .animation(FileBrowserMetrics.pageChange, value: opened)
        .task { await model.load() }
        .accessibilityIdentifier(UIIdentifier.Workspace.browser)
    }

    private var directory: some View {
        VStack(spacing: 0) {
            WorkspacePathHeader(components: model.breadcrumb, isAtRoot: model.isAtRoot) {
                Task { await model.goUp() }
            }
            content
        }
        .background(Theme.surface.base)
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            LoadingView(.screen(label: "Loading files"))
        case .failure(let state):
            ErrorStateView(state: state) { Task { await model.load() } }
        case .loaded(let listing):
            list(listing)
        }
    }

    private func list(_ listing: DirectoryListing) -> some View {
        List {
            if listing.entries.isEmpty {
                Text("Empty directory")
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.secondary)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            ForEach(listing.entries) { entry in
                Button {
                    open(entry)
                } label: {
                    FileEntryRow(entry: entry)
                }
                .buttonStyle(.plain)
                .catalogRowChrome()
            }
            if listing.isTruncated {
                Text("Showing the first \(DirectoryListingCommand.entryLimit) entries")
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.text.tertiary)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .catalogListSurface()
    }

    private func open(_ entry: DirectoryEntry) {
        guard !entry.isDirectory else {
            Task { await model.enter(entry) }
            return
        }
        opened = OpenedFile(path: model.fullPath(of: entry), name: entry.name)
    }

    private func close() {
        opened = nil
    }
}
#endif
