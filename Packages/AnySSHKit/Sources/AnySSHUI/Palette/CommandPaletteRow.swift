import SwiftUI

struct CommandPaletteRow: View {
    let entry: PaletteEntry
    let isSelected: Bool

    var body: some View {
        SurfaceCard(isSelected: isSelected) {
            HStack(spacing: Theme.Space.step3) {
                VStack(alignment: .leading, spacing: Theme.Space.step1) {
                    Text(entry.title)
                        .font(Theme.Text.body)
                        .foregroundStyle(entry.isEnabled ? Theme.text.primary : Theme.text.tertiary)
                    if let reason = entry.disabledReason {
                        Text(reason)
                            .font(Theme.Text.caption)
                            .foregroundStyle(Theme.text.tertiary)
                    }
                }
                Spacer(minLength: 0)
                if let key = entry.keyLabel {
                    Text(key)
                        .font(Theme.Text.caption)
                        .foregroundStyle(entry.isEnabled ? Theme.text.secondary : Theme.text.tertiary)
                }
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(CommandPaletteIdentifier.row(entry.id))
    }
}

#Preview("CommandPaletteRow") {
    ThemedRoot {
        VStack(spacing: Theme.Space.rowGap) {
            CommandPaletteRow(
                entry: PaletteEntry(
                    id: "app.newConnection",
                    title: "New Connection",
                    keyLabel: "Cmd+N",
                    isEnabled: true,
                    disabledReason: nil
                ),
                isSelected: true
            )
            CommandPaletteRow(
                entry: PaletteEntry(
                    id: "session.next",
                    title: "Next Session",
                    keyLabel: nil,
                    isEnabled: false,
                    disabledReason: "One session open"
                ),
                isSelected: false
            )
        }
        .padding(Theme.Space.screenMargin)
    }
}
