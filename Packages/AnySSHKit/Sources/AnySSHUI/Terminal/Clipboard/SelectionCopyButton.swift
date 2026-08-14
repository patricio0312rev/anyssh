import SwiftUI

public struct SelectionCopyButton: View {
    private let text: String
    private let copy: (String) -> Void

    public init(text: String, copy: @escaping (String) -> Void) {
        self.text = text
        self.copy = copy
    }

    public var body: some View {
        VStack(spacing: Theme.Space.step2) {
            Text(text)
                .font(Theme.code())
                .foregroundStyle(Theme.text.primary)
                .accessibilityIdentifier(UIIdentifier.Terminal.Clipboard.selection)
                .accessibilityValue(text)
            Button("Copy") { copy(text) }
                .buttonStyle(.raised)
                .accessibilityIdentifier(UIIdentifier.Terminal.Clipboard.copy)
        }
    }
}
