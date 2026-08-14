#if canImport(UIKit)
import AnySSHCore
import SwiftUI

extension SessionWorkspaceView {
    func openFailure(_ failure: ErrorState) -> some View {
        ErrorStateView(state: failure) {
            Task { await model.retryActiveSession() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.surface.base)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(UIIdentifier.Session.openFailure)
    }

    func axByteCounter(_ bytes: Int) -> some View {
        Text(String(bytes))
            .font(Theme.Text.caption)
            .foregroundStyle(Theme.text.tertiary)
            .frame(width: 1, height: 1)
            .opacity(0)
            .accessibilityIdentifier(SessionSwitcherIdentifier.byteCounter)
            .accessibilityHidden(true)
    }

    func axNotificationProbe() -> some View {
        let last = model.systemNotificationRequests.last
        let record = [
            String(model.systemNotificationRequests.count),
            last?.alert.title ?? "",
            last?.alert.body ?? "",
        ]
        return Text(record.joined(separator: "|"))
            .font(Theme.Text.caption)
            .foregroundStyle(Theme.text.tertiary)
            .frame(width: 1, height: 1)
            .opacity(0)
            .accessibilityIdentifier(UIIdentifier.JobAlerts.systemRequests)
            .accessibilityHidden(true)
    }

    var empty: some View {
        VStack(spacing: Theme.Space.step5) {
            VStack(spacing: Theme.Space.step2) {
                Text("No open sessions")
                    .font(Theme.Text.sectionHeader)
                    .foregroundStyle(Theme.text.primary)
                Text(
                    model.lastRemote.map { "You closed the last session on \($0.name)." }
                        ?? "Sessions you open appear here."
                )
                .font(Theme.Text.body)
                .foregroundStyle(Theme.text.secondary)
                .multilineTextAlignment(.center)
            }
            VStack(spacing: Theme.Space.step3) {
                if let remote = model.lastRemote {
                    Button("New Session") {
                        Task { await model.open(remote: remote) }
                    }
                    .buttonStyle(.accentCapsule)
                    .accessibilityIdentifier(UIIdentifier.Session.newSession)
                    Button("Back to Remotes", action: dismissToRemotes)
                        .buttonStyle(.raised)
                        .accessibilityIdentifier(UIIdentifier.Session.backToRemotes)
                } else {
                    Button("Back to Remotes", action: dismissToRemotes)
                        .buttonStyle(.accentCapsule)
                        .accessibilityIdentifier(UIIdentifier.Session.backToRemotes)
                }
            }
            .controlSize(.large)
        }
        .padding(Theme.Space.screenMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(UIIdentifier.Session.workspaceEmpty)
    }
}
#endif
