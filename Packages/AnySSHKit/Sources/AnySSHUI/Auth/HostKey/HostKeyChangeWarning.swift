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

            SurfaceCard {
                VStack(spacing: Theme.Space.rowGap) {
                    CopyableRow(
                        label: "Stored for \(prompt.target)",
                        value: prompt.storedFingerprint ?? "",
                        monospaced: true,
                        accessibilityIdentifier: UIIdentifier.Trust.storedFingerprint
                    )
                    Divider().overlay(Theme.separator)
                    CopyableRow(
                        label: "Offered now (\(prompt.algorithmName))",
                        value: prompt.offeredFingerprint,
                        monospaced: true,
                        accessibilityIdentifier: UIIdentifier.Trust.offeredFingerprint
                    )
                }
            }

            VStack(spacing: Theme.Space.step2) {
                SheetActionButton(
                    copy.recoveryLabel,
                    emphasis: .primary,
                    accessibilityIdentifier: UIIdentifier.Trust.cancel,
                    action: cancel
                )
                SheetActionButton(
                    "Forget This Host",
                    emphasis: .destructive,
                    accessibilityIdentifier: UIIdentifier.Trust.forget,
                    action: forget
                )
            }
        }
        .padding(Theme.Space.step5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.surface.base)
        .overlay(alignment: .topLeading) { ScreenMarker(state: ErrorState.trust(.hostKeyChanged)) }
    }
}
