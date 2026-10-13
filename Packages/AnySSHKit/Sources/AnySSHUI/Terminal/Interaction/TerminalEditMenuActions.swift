#if canImport(UIKit)
import TerminalEmulator
import UIKit

@MainActor
enum TerminalEditMenuActions {
    static func elements(for context: TerminalSelectionContext) -> [UIMenuElement] {
        switch context {
        case .none:
            return []
        case .url(let value):
            return [
                UIAction(title: "Open Link") { _ in
                    guard let url = URL(string: value) else { return }
                    UIApplication.shared.open(url)
                },
                copyAction(title: "Copy Link", value: value),
            ]
        case .path(let value):
            return [copyAction(title: "Copy Path", value: value)]
        }
    }

    static func pasteImage(_ handler: @escaping @MainActor @Sendable () -> Void) -> UIAction {
        UIAction(title: "Paste Image", image: UIImage(systemName: "photo")) { _ in handler() }
    }

    static func withoutPaste(_ elements: [UIMenuElement]) -> [UIMenuElement] {
        elements.compactMap { element -> UIMenuElement? in
            if let command = element as? UICommand,
                command.action == #selector(UIResponderStandardEditActions.paste(_:))
            {
                return nil
            }
            guard let menu = element as? UIMenu else { return element }
            return menu.replacingChildren(withoutPaste(menu.children))
        }
    }

    private static func copyAction(title: String, value: String) -> UIAction {
        UIAction(title: title) { _ in
            SystemClipboardPasteboard().write(value)
        }
    }
}
#endif
