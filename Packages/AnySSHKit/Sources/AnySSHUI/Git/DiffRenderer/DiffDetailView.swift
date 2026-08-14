#if canImport(UIKit)
import AnySSHCore
import Foundation
import SwiftUI

public struct DiffDetailView: View {
    private let file: ChangedFile
    private let repository: RepositoryRef
    private let git: any GitService

    @State private var state: DiffLoadState = .loading

    private enum DiffLoadState {
        case loading
        case loaded(FileDiff)
        case failed(ErrorState)
    }

    public init(file: ChangedFile, repository: RepositoryRef, git: any GitService) {
        self.file = file
        self.repository = repository
        self.git = git
    }

    public var body: some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
            .accessibilityIdentifier(UIIdentifier.Diff.detail)
            .task { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            LoadingView(.screen(label: "Loading diff"))
                .background(Theme.surface.base)
        case .loaded(let diff):
            DiffRenderer(diff: diff)
        case .failed(let error):
            if Self.reloadIsTheRecovery(error) {
                ErrorStateView(state: error) { Task { await load() } }
            } else {
                ErrorStateView(state: error)
            }
        }
    }

    private var title: String {
        guard let path = file.newPath ?? file.oldPath else { return "Diff" }
        return (path as NSString).lastPathComponent
    }

    private static func reloadIsTheRecovery(_ error: ErrorState) -> Bool {
        switch error {
        case .git(.diffTruncated), .git(.binaryDiff), .git(.submoduleEntry),
            .git(.combinedDiffUnsupported), .git(.modeOnlyChange):
            false
        default:
            true
        }
    }

    private func load() async {
        state = .loading
        do {
            state = .loaded(try await git.diff(for: file, in: repository, staged: false))
        } catch let error as ErrorState {
            state = .failed(error)
        } catch {
            state = .failed(.git(.diffTruncated))
        }
    }
}
#endif
