import SwiftUI

public struct SettingsRow: View {
    private let title: String
    private let subtitle: String
    private let systemImage: String

    public init(title: String, subtitle: String, systemImage: String) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: Theme.Space.step3) {
            Image(systemName: systemImage)
                .font(Theme.Text.body)
                .foregroundStyle(Theme.text.secondary)
                .frame(width: Theme.Space.step5)
            VStack(alignment: .leading, spacing: Theme.Space.step1) {
                Text(title)
                    .font(Theme.Text.body)
                    .foregroundStyle(Theme.text.primary)
                Text(subtitle)
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.text.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview("SettingsRow") {
    ThemedRoot {
        SurfaceCard {
            VStack(spacing: Theme.Space.rowGap) {
                SettingsRow(
                    title: "Gestures",
                    subtitle: "What a swipe sends to the terminal",
                    systemImage: "hand.draw"
                )
                SettingsRow(
                    title: "Snippets",
                    subtitle: "Commands you send often",
                    systemImage: "text.append"
                )
            }
        }
        .padding(Theme.Space.screenMargin)
    }
}
