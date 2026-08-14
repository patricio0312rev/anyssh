import SwiftUI

public struct CloseButton: View {
    private let accessibilityIdentifier: String
    private let action: () -> Void

    public init(accessibilityIdentifier: String, action: @escaping () -> Void) {
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(Theme.Text.body)
                .foregroundStyle(Theme.text.secondary)
                .frame(width: Theme.Buttons.iconHitTarget, height: Theme.Buttons.iconHitTarget)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

#Preview("CloseButton") {
    ThemedRoot {
        CloseButton(accessibilityIdentifier: "preview.close") {}
    }
}
