#if canImport(UIKit)
import AnySSHCore
import SwiftUI

struct FileDiffDisclosure: View {
    let file: ChangedFile
    let identifier: String
    var isUntracked = false
    var load: (() async throws -> FileDiff)?
    var loaded: FileDiff?
    var startsExpanded = false

    @State private var isExpanded = false
    @State private var state: LoadState = .idle

    private enum LoadState {
        case idle
        case loading
        case ready(FileDiff)
        case failed(ErrorState)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            body(for: state)
        } label: {
            ChangedFileRow(file: file, identifier: identifier, isUntracked: isUntracked)
                .contentShape(.rect)
                .onTapGesture { withAnimation(Theme.Motion.standard) { isExpanded.toggle() } }
        }
        .tint(Theme.text.tertiary)
        .onAppear { isExpanded = isExpanded || startsExpanded }
        .task(id: isExpanded) { await loadIfNeeded() }
    }

    @ViewBuilder
    private func body(for state: LoadState) -> some View {
        switch state {
        case .idle, .loading:
            if let loaded {
                diff(loaded)
            } else {
                LoadingView(.inline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Space.step4)
            }
        case .ready(let ready):
            diff(ready)
        case .failed(let error):
            Text(error.copy.title)
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Theme.Space.step2)
        }
    }

    private func diff(_ diff: FileDiff) -> some View {
        DiffRenderer(diff: diff)
            .frame(maxHeight: DiffMetrics.inlineHeight)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Space.controlRadius, style: .continuous))
            .padding(.top, Theme.Space.step2)
    }

    private func loadIfNeeded() async {
        guard isExpanded, case .idle = state, let load else { return }
        state = .loading
        do {
            state = .ready(try await load())
        } catch let error as ErrorState {
            state = .failed(error)
        } catch {
            state = .failed(.git(.diffTruncated))
        }
    }
}
#endif
