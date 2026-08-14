import AnySSHCore
import SwiftUI

public struct HostKeyFirstUseSheet: View {
    private let copy = ErrorState.trust(.firstUse).copy

    let prompt: HostKeyPrompt
    let accept: () -> Void
    let reject: () -> Void
    let cancel: () -> Void

    public init(
        prompt: HostKeyPrompt,
        accept: @escaping () -> Void,
        reject: @escaping () -> Void,
        cancel: @escaping () -> Void
    ) {
        self.prompt = prompt
        self.accept = accept
        self.reject = reject
        self.cancel = cancel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step5) {
            VStack(alignment: .leading, spacing: Theme.Space.step2) {
                Text(copy.title)
                    .font(Theme.Text.screenTitle)
                    .foregroundStyle(Theme.text.primary)
                Text(copy.body)
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.secondary)
            }
            .accessibilityElement(children: .combine)

            SurfaceCard {
                CopyableRow(
                    label: "\(prompt.target) (\(prompt.algorithmName))",
                    value: prompt.offeredFingerprint,
                    monospaced: true,
                    accessibilityIdentifier: UIIdentifier.Trust.offeredFingerprint
                )
            }

            VStack(spacing: Theme.Space.step2) {
                SheetActionButton(
                    copy.recoveryLabel,
                    emphasis: .primary,
                    accessibilityIdentifier: UIIdentifier.Trust.accept,
                    action: accept
                )
                SheetActionButton(
                    "Reject",
                    emphasis: .destructive,
                    accessibilityIdentifier: UIIdentifier.Trust.reject,
                    action: reject
                )
                SheetActionButton(
                    "Cancel",
                    accessibilityIdentifier: UIIdentifier.Trust.cancel,
                    action: cancel
                )
            }
        }
        .padding(Theme.Space.step5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.surface.base)
        .overlay(alignment: .topLeading) { ScreenMarker(state: ErrorState.trust(.firstUse)) }
    }
}
