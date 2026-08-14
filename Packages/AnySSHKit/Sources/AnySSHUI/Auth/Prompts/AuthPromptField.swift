import AnySSHCore
import SwiftUI

struct AuthPromptField: View {
    let prompt: AuthPrompt
    let index: Int

    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step1) {
            Text(prompt.text)
                .font(Theme.Text.sectionHeader)
                .foregroundStyle(Theme.text.secondary)
            field
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .accessibilityIdentifier(UIIdentifier.Auth.field(index))
                .accessibilityLabel(prompt.text)
        }
    }

    @ViewBuilder private var field: some View {
        if prompt.isEchoed {
            TextField(prompt.text, text: $value)
        } else {
            SecureField(prompt.text, text: $value)
        }
    }
}
