import SwiftUI

public struct AuthSavePasswordSheet: View {
    private let onSave: () -> Void
    private let onSkip: () -> Void

    public static let detentHeight: CGFloat = 200

    public init(onSave: @escaping () -> Void, onSkip: @escaping () -> Void) {
        self.onSave = onSave
        self.onSkip = onSkip
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step3) {
            Text("Save password?")
                .font(Theme.Text.sectionHeader)
                .foregroundStyle(Theme.text.primary)
            Text("Store it on the device so the next connection does not ask again.")
                .font(Theme.Text.body)
                .foregroundStyle(Theme.text.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Theme.Space.step3) {
                SheetActionButton(
                    "Not Now",
                    accessibilityIdentifier: UIIdentifier.Auth.savePasswordSkip,
                    action: onSkip
                )
                SheetActionButton(
                    "Save Password",
                    emphasis: .primary,
                    accessibilityIdentifier: UIIdentifier.Auth.savePasswordConfirm,
                    action: onSave
                )
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Theme.Space.screenMargin)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Theme.surface.base)
        .accessibilityIdentifier(UIIdentifier.Auth.savePassword)
    }
}

#Preview("AuthSavePasswordSheet") {
    ThemedRoot {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                AuthSavePasswordSheet(onSave: {}, onSkip: {})
                    .presentationDetents([.height(AuthSavePasswordSheet.detentHeight)])
                    .presentationDragIndicator(.visible)
            }
    }
}
