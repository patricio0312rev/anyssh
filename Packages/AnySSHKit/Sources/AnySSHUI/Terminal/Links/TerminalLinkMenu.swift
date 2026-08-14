#if canImport(UIKit)
import AnySSHCore
import TerminalEmulator
import UIKit

@MainActor
public enum TerminalLinkMenu {
    public static func actions(
        for span: LinkSpan,
        present: @escaping (URL) -> Void,
        refuse: @escaping (ErrorState) -> Void,
        copyAddress: @escaping (String) -> Void,
        copySelection: @escaping (String) -> Void
    ) -> [UIAction] {
        [
            openAction(for: span, present: present, refuse: refuse),
            copyLinkAction(for: span, copyAddress: copyAddress),
            copyAction(for: span, copySelection: copySelection),
        ]
    }

    private static func openAction(
        for span: LinkSpan,
        present: @escaping (URL) -> Void,
        refuse: @escaping (ErrorState) -> Void
    ) -> UIAction {
        let action = UIAction(
            title: "Open",
            image: nil,
            identifier: UIAction.Identifier(UIIdentifier.Terminal.Links.open)
        ) { _ in
            switch LinkSchemePolicy.outcome(for: span.url) {
            case .open: present(span.url)
            case .refused(let state): refuse(state)
            }
        }
        action.accessibilityIdentifier = UIIdentifier.Terminal.Links.open
        return action
    }

    private static func copyLinkAction(
        for span: LinkSpan,
        copyAddress: @escaping (String) -> Void
    ) -> UIAction {
        let action = UIAction(
            title: "Copy Link",
            image: nil,
            identifier: UIAction.Identifier(UIIdentifier.Terminal.Links.copyLink)
        ) { _ in
            copyAddress(span.url.absoluteString)
        }
        action.accessibilityIdentifier = UIIdentifier.Terminal.Links.copyLink
        return action
    }

    private static func copyAction(
        for span: LinkSpan,
        copySelection: @escaping (String) -> Void
    ) -> UIAction {
        let action = UIAction(
            title: "Copy",
            image: nil,
            identifier: UIAction.Identifier(UIIdentifier.Terminal.Links.copy)
        ) { _ in
            copySelection(span.text)
        }
        action.accessibilityIdentifier = UIIdentifier.Terminal.Links.copy
        return action
    }
}
#endif
