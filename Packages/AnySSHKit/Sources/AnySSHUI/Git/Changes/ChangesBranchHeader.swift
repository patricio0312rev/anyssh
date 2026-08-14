#if canImport(UIKit)
import AnySSHCore
import SwiftUI

struct ChangesBranchHeader: View {
    let location: WorkspaceLocation
    let status: RepositoryStatus

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step1) {
            HStack(spacing: Theme.Space.step2) {
                Text(branchTitle)
                    .font(Theme.Text.sectionHeader)
                    .foregroundStyle(Theme.text.primary)
                if !status.unmerged.isEmpty {
                    Label("Merge", systemImage: "exclamationmark.triangle")
                        .font(Theme.Text.caption)
                        .foregroundStyle(Theme.status.attention)
                }
                Spacer(minLength: Theme.Space.step2)
                Text(trackingText)
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.text.secondary)
            }
            Text(location.path)
                .font(Theme.code())
                .foregroundStyle(Theme.text.tertiary)
                .lineLimit(1)
                .truncationMode(.head)
        }
        .padding(.horizontal, Theme.Space.screenMargin)
        .padding(.bottom, Theme.Space.rowGap)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(UIIdentifier.Changes.header)
    }

    private var branchTitle: String {
        switch status.head {
        case .branch(let name): name
        case .unborn(let name): ErrorState.git(.unbornBranch).copy.title + " · " + name
        case .detached: ErrorState.git(.detachedHead).copy.title
        }
    }

    private var trackingText: String {
        if !status.unmerged.isEmpty { return ErrorState.git(.mergeInProgress).copy.title }
        guard let upstream = status.upstream else { return ErrorState.git(.noUpstream).copy.title }
        switch (upstream.ahead, upstream.behind) {
        case (0, 0): return "Up to date"
        case (_, 0): return "Ahead \(upstream.ahead)"
        case (0, _): return "Behind \(upstream.behind)"
        default: return "Ahead \(upstream.ahead), behind \(upstream.behind)"
        }
    }
}
#endif
