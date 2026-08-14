#if canImport(UIKit)
import AnySSHCore
import GitClient
import SwiftUI

public struct WorkspaceBrowserSheet: View {
    private let resolve: @Sendable () async -> WorkspaceLocation?
    private let git: any GitService
    private let files: any RemoteFileBrowser

    @State private var mode: WorkspaceBrowserMode
    @State private var location: WorkspaceLocation?
    @State private var isResolving: Bool

    public init(
        location: WorkspaceLocation?,
        mode: WorkspaceBrowserMode = .changes,
        resolve: @escaping @Sendable () async -> WorkspaceLocation?,
        git: any GitService,
        files: any RemoteFileBrowser
    ) {
        self.resolve = resolve
        self.git = git
        self.files = files
        _mode = State(initialValue: mode)
        _location = State(initialValue: location)
        _isResolving = State(initialValue: location == nil)
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle(mode.title)
                .toolbar { toggleItem }
                .accessibilityIdentifier(UIIdentifier.Workspace.sheet)
        }
        .task { await resolveIfNeeded() }
    }

    @ToolbarContentBuilder
    private var toggleItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            IconButton(
                systemImage: mode.toggleIcon,
                label: mode.toggleLabel,
                surface: .toolbar,
                accessibilityIdentifier: UIIdentifier.Workspace.modeToggle
            ) {
                withAnimation(Theme.Motion.overlay) { mode = mode.next }
            }
            .disabled(location == nil)
        }
    }

    @ViewBuilder
    private var content: some View {
        if isResolving {
            LoadingView(.screen(label: "Finding the working directory"))
                .accessibilityIdentifier(UIIdentifier.Workspace.resolving)
        } else if let location {
            switch mode {
            case .changes:
                ChangesListView(location: location, git: git)
                    .transition(.opacity)
            case .files:
                FileBrowserView(root: location.path, browser: files)
                    .transition(.opacity)
            }
        } else {
            ErrorStateView(state: .git(.notARepository)) {
                Task { await retry() }
            }
        }
    }

    private func resolveIfNeeded() async {
        guard location == nil else { return }
        for attempt in 0..<Self.attempts {
            if let resolved = await resolve() {
                location = resolved
                isResolving = false
                return
            }
            guard attempt + 1 < Self.attempts else { break }
            try? await Task.sleep(for: Self.retryDelay)
        }
        isResolving = false
    }

    private func retry() async {
        isResolving = true
        await resolveIfNeeded()
    }

    private static let attempts = 5
    private static let retryDelay = Duration.milliseconds(600)
}
#endif
