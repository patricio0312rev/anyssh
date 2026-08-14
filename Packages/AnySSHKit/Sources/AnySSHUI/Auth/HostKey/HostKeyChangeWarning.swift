import AnySSHCore
import SwiftUI

public struct HostKeyChangeWarning: View {
    private let copy = ErrorState.trust(.hostKeyChanged).copy

    let prompt: HostKeyPrompt
    let cancel: () -> Void
    let forget: () -> Void

    public init(prompt: HostKeyPrompt, cancel: @escaping () -> Void, forget: @escaping () -> Void) {
        self.prompt = prompt
        self.cancel = cancel
        self.forget = forget
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step5) {
            VStack(alignment: .leading, spacing: Theme.Space.step2) {
                Label(copy.title, systemImage: "exclamationmark.triangle.fill")
                    .font(Theme.Text.screenTitle)
                    .foregroundStyle(Theme.destructive)
                Text(copy.body)
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.secondary)
            }
            .accessibilityElement(children: .combine)

            VStack(alignment: .leading, spacing: Theme.Space.step3) {
                HostKeyFingerprintRow(
                    label: "Stored for \(prompt.target)",
                    fingerprint: prompt.storedFingerprint ?? "",
                    identifier: UIIdentifier.Trust.storedFingerprint
                )
                HostKeyFingerprintRow(
                    label: "Offered now (\(prompt.algorithmName))",
                    fingerprint: prompt.offeredFingerprint,
                    identifier: UIIdentifier.Trust.offeredFingerprint
                )
            }

            VStack(spacing: Theme.Space.step3) {
                Button(copy.recoveryLabel, action: cancel)
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .accessibilityIdentifier(UIIdentifier.Trust.cancel)
                Button("Forget This Host", role: .destructive, action: forget)
                    .accessibilityIdentifier(UIIdentifier.Trust.forget)
            }
            .frame(maxWidth: .infinity)
            .controlSize(.large)
        }
        .padding(Theme.Space.step5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .overlay(alignment: .topLeading) { ScreenMarker(state: ErrorState.trust(.hostKeyChanged)) }
    }
}
