import SwiftUI

public struct StatusDot: View {
    private let color: Color
    private let label: String
    private let value: String
    private let accessibilityIdentifier: String

    public init(color: Color, label: String, value: String, accessibilityIdentifier: String) {
        self.color = color
        self.label = label
        self.value = value
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    public var body: some View {
        Circle()
            .fill(color)
            .frame(width: Theme.Space.statusDot, height: Theme.Space.statusDot)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityIdentifier(accessibilityIdentifier)
    }
}

#Preview("StatusDot") {
    ThemedRoot {
        HStack(spacing: Theme.Space.step4) {
            StatusDot(
                color: Theme.status.online,
                label: "Status",
                value: "online",
                accessibilityIdentifier: "preview.dot.online"
            )
            StatusDot(
                color: Theme.status.busy,
                label: "Status",
                value: "busy",
                accessibilityIdentifier: "preview.dot.busy"
            )
            StatusDot(
                color: Theme.status.attention,
                label: "Status",
                value: "blocked",
                accessibilityIdentifier: "preview.dot.attention"
            )
        }
        .padding(Theme.Space.screenMargin)
    }
}
