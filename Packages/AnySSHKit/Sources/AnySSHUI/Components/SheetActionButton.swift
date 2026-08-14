import SwiftUI

public struct SheetActionButton: View {
    public enum Emphasis: Sendable {
        case primary
        case standard
        case destructive
    }

    private let title: String
    private let emphasis: Emphasis
    private let accessibilityIdentifier: String
    private let action: () -> Void

    public init(
        _ title: String,
        emphasis: Emphasis = .standard,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.emphasis = emphasis
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }

    public var body: some View {
        switch emphasis {
        case .primary:
            button.buttonStyle(.glassProminent).tint(Theme.accent)
        case .standard:
            button.buttonStyle(.plain).foregroundStyle(Theme.text.secondary)
        case .destructive:
            button.buttonStyle(.plain).foregroundStyle(Theme.destructive)
        }
    }

    private var button: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Text.body)
                .frame(maxWidth: .infinity, minHeight: Theme.Buttons.height)
                .contentShape(.rect)
        }
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

#Preview("SheetActionButton") {
    ThemedRoot {
        VStack(spacing: Theme.Space.step3) {
            SheetActionButton("Accept", emphasis: .primary, accessibilityIdentifier: "p") {}
            SheetActionButton("Reject", emphasis: .destructive, accessibilityIdentifier: "d") {}
            SheetActionButton("Cancel", accessibilityIdentifier: "s") {}
        }
        .padding(Theme.Space.screenMargin)
    }
}
