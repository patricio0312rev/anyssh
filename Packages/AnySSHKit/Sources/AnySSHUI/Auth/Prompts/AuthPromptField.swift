import AnySSHCore
import SwiftUI

struct AuthPromptField: View {
    let prompt: AuthPrompt
    let index: Int

    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step1) {
            Text(prompt.text)
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.tertiary)
            field
                .font(Theme.Text.body)
                .foregroundStyle(Theme.text.primary)
                .autocorrectionDisabled()
                .padding(.horizontal, Theme.Space.step3)
                .frame(maxWidth: .infinity, minHeight: Theme.Buttons.height, alignment: .leading)
                .background(
                    Theme.surface.overlay,
                    in: RoundedRectangle(
                        cornerRadius: Theme.Space.controlRadius,
                        style: .continuous
                    )
                )
                .accessibilityIdentifier(UIIdentifier.Auth.field(index))
                .accessibilityLabel(prompt.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var field: some View {
        if prompt.isEchoed {
            TextField("", text: $value)
        } else {
            SecureField("", text: $value)
        }
    }
}
