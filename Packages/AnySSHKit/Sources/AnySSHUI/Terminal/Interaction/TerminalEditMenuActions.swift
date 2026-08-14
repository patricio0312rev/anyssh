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

    private static func copyAction(title: String, value: String) -> UIAction {
        UIAction(title: title) { _ in
            SystemClipboardPasteboard().write(value)
        }
    }
}
#endif
