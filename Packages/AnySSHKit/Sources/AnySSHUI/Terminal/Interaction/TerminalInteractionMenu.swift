#if canImport(UIKit)
import AnySSHCore
import TerminalEmulator
import UIKit

extension TerminalInteractionCoordinator {
    public func editMenuInteraction(
        _ interaction: UIEditMenuInteraction,
        menuFor configuration: UIEditMenuConfiguration,
        suggestedActions: [UIMenuElement]
    ) -> UIMenu? {
        let text = selectionText()
        let clipboard = SystemClipboardPasteboard().contentKinds()
        var children =
            clipboard.hasImage && !clipboard.hasText
            ? TerminalEditMenuActions.withoutPaste(suggestedActions)
            : suggestedActions
        if !text.isEmpty {
            children.insert(
                UIAction(title: "Copy") { [weak self] _ in self?.copySelectionText(text) },
                at: 0
            )
        }
        children += TerminalEditMenuActions.elements(
            for: TerminalSelectionContext.detect(in: text)
        )
        if clipboard.hasImage, let imagePasteHandler {
            children.append(TerminalEditMenuActions.pasteImage(imagePasteHandler))
        }
        return UIMenu(children: children)
    }

    public func editMenuInteraction(
        _ interaction: UIEditMenuInteraction,
        targetRectFor configuration: UIEditMenuConfiguration
    ) -> CGRect {
        selectionMenuRect()
    }
}
#endif
