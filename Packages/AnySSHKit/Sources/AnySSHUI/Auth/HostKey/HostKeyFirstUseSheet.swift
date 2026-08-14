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
                Text(copy.body)
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.secondary)
            }
            .accessibilityElement(children: .combine)

            HostKeyFingerprintRow(
                label: "\(prompt.target) (\(prompt.algorithmName))",
                fingerprint: prompt.offeredFingerprint,
                identifier: UIIdentifier.Trust.offeredFingerprint
            )

            VStack(spacing: Theme.Space.step3) {
                Button(copy.recoveryLabel, action: accept)
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .accessibilityIdentifier(UIIdentifier.Trust.accept)
                Button("Reject", role: .destructive, action: reject)
                    .accessibilityIdentifier(UIIdentifier.Trust.reject)
                Button("Cancel", action: cancel)
                    .accessibilityIdentifier(UIIdentifier.Trust.cancel)
            }
            .frame(maxWidth: .infinity)
            .controlSize(.large)
        }
        .padding(Theme.Space.step5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .topLeading) { ScreenMarker(state: ErrorState.trust(.firstUse)) }
    }
}
