import SwiftUI

enum RemoteFormKeyboard {
    case text
    case number
    case address
    case password
}

struct RemoteFormField: View {
    static let labelWidth: CGFloat = 92

    let title: String
    let identifier: String

    @Binding var text: String

    let message: String?
    let placeholder: String
    var keyboard: RemoteFormKeyboard = .text

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step1) {
            HStack {
                Text(title)
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.primary)
                    .frame(width: Self.labelWidth, alignment: .leading)
                field
                    .autocorrectionDisabled()
                    .foregroundStyle(Theme.text.primary)
                    .accessibilityIdentifier(identifier)
                    .accessibilityLabel(title)
            }
            if let message {
                Text(message)
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.status.error)
                    .accessibilityIdentifier(UIIdentifier.RemoteForm.message(identifier))
            }
        }
    }

    @ViewBuilder
    private var field: some View {
        switch keyboard {
        case .password:
            SecureField(placeholder, text: $text)
                .textContentType(.password)
        case .text, .number, .address:
            #if canImport(UIKit)
            TextField(placeholder, text: $text)
                .keyboardType(keyboard.uiKeyboardType)
                .textInputAutocapitalization(.never)
            #else
            TextField(placeholder, text: $text)
            #endif
        }
    }
}

#if canImport(UIKit)
import UIKit

extension RemoteFormKeyboard {
    var uiKeyboardType: UIKeyboardType {
        switch self {
        case .text, .password: .default
        case .number: .numberPad
        case .address: .URL
        }
    }
}
#endif
