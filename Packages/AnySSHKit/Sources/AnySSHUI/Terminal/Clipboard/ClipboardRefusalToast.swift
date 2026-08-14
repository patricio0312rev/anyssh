import Foundation
import TerminalEmulator

extension StatusToast {
    public init(
        id: UUID = UUID(),
        refusal: ClipboardRefusal,
        dismiss: @escaping @MainActor @Sendable () -> Void
    ) {
        let copy = refusal.copy
        self.init(
            id: id,
            severity: Self.severity(for: refusal),
            title: copy.title,
            body: copy.body,
            accessibilityIdentifier: refusal.accessibilityIdentifier,
            action: StatusToastAction(
                title: copy.recoveryLabel,
                accessibilityIdentifier: UIIdentifier.Terminal.Clipboard.dismissHint,
                handler: dismiss
            ),
            onDismiss: dismiss
        )
    }

    private static func severity(for refusal: ClipboardRefusal) -> StatusToastSeverity {
        switch refusal {
        case .tooLarge, .denied:
            .error
        case .pasteCancelled, .tmuxClipboardOff:
            .attention
        }
    }
}
