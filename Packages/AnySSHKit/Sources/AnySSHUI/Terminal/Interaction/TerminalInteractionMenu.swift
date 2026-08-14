#if canImport(UIKit)
import TerminalEmulator
import UIKit

extension TerminalInteractionCoordinator {
    public func editMenuInteraction(
        _ interaction: UIEditMenuInteraction,
        menuFor configuration: UIEditMenuConfiguration,
        suggestedActions: [UIMenuElement]
    ) -> UIMenu? {
        let text = selectionText()
        var children = suggestedActions
        if !text.isEmpty {
            children.insert(
                UIAction(title: "Copy") { [weak self] _ in self?.copySelectionText(text) },
                at: 0
            )
        }
        children += TerminalEditMenuActions.elements(
            for: TerminalSelectionContext.detect(in: text)
        )
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
