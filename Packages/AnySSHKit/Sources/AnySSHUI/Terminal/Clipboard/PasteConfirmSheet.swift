import SwiftUI
import TerminalEmulator

public struct PasteConfirmSheet: View {
    private let content: PasteConfirmationContent
    private let confirm: () -> Void
    private let cancel: () -> Void

    public init(
        content: PasteConfirmationContent,
        confirm: @escaping () -> Void,
        cancel: @escaping () -> Void
    ) {
        self.content = content
        self.confirm = confirm
        self.cancel = cancel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.step4) {
            Text("Paste \(content.lineCount) lines?")
                .font(Theme.Text.sectionHeader)
                .foregroundStyle(Theme.text.primary)
                .accessibilityIdentifier(UIIdentifier.Terminal.Paste.lineCount)
                .accessibilityValue("\(content.lineCount)")

            Text(content.preview)
                .font(Theme.code())
                .foregroundStyle(Theme.Code.foreground)
                .lineLimit(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Space.cardPadding)
                .background(Theme.Code.canvas)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Space.controlRadius))
                .accessibilityIdentifier(UIIdentifier.Terminal.Paste.preview)

            if content.endsWithLineBreak {
                Text("The last line ends with a break and will run on arrival.")
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.text.secondary)
            }

            HStack(spacing: Theme.Space.step3) {
                SheetActionButton(
                    "Cancel",
                    accessibilityIdentifier: UIIdentifier.Terminal.Paste.cancel,
                    action: cancel
                )
                SheetActionButton(
                    "Paste",
                    emphasis: .primary,
                    accessibilityIdentifier: UIIdentifier.Terminal.Paste.confirm,
                    action: confirm
                )
            }
        }
        .padding(Theme.Space.screenMargin)
        .frame(maxWidth: .infinity)
        .background(Theme.surface.base)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(UIIdentifier.Terminal.Paste.sheet)
    }
}
