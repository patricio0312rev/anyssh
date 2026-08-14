#if canImport(UIKit)
import AnySSHCore
import SwiftUI
import TerminalEmulator
import UIKit

public struct TerminalLinkScenarioView: View {
    public init() {}

    public var body: some View {
        TerminalLinkScenarioRepresentable()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.surface.base)
    }
}

@MainActor
final class TerminalLinkScenarioController: UIViewController, UIContextMenuInteractionDelegate {
    private let grid = TerminalLinkGridView()
    private let copied = UILabel()
    private let opener = TerminalLinkOpener { nil }
    private var activeSpan: LinkSpan?
    private let pasteboard: UIPasteboard

    init(pasteboard: UIPasteboard = .general) {
        self.pasteboard = pasteboard
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        preconditionFailure("TerminalLinkScenarioController is created in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Platform.surfaceBase
        grid.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            grid.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            grid.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            grid.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        grid.addInteraction(UIContextMenuInteraction(delegate: self))
        grid.accessibilityIdentifier = UIIdentifier.Terminal.canvas
        installCopiedProbe()
        opener.presenting = { [weak self] in self }
    }

    private func installCopiedProbe() {
        copied.translatesAutoresizingMaskIntoConstraints = false
        copied.isAccessibilityElement = true
        copied.accessibilityIdentifier = UIIdentifier.Terminal.Links.copied
        copied.accessibilityValue = ""
        copied.alpha = 0.01
        view.addSubview(copied)
        NSLayoutConstraint.activate([
            copied.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            copied.topAnchor.constraint(equalTo: view.topAnchor),
            copied.widthAnchor.constraint(equalToConstant: 1),
            copied.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    private func note(copied text: String) {
        pasteboard.string = text
        copied.accessibilityValue = text
    }

    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        activeSpan = grid.span(at: location)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            self?.menu()
        }
    }

    private func menu() -> UIMenu {
        if let span = activeSpan {
            let actions = TerminalLinkMenu.actions(
                for: span,
                present: { [weak self] url in self?.opener.open(url) },
                refuse: { [weak self] state in self?.opener.refuse(state) },
                copyAddress: { [weak self] address in self?.note(copied: address) },
                copySelection: { [weak self] text in self?.note(copied: text) }
            )
            return UIMenu(children: actions)
        }
        return UIMenu(children: [
            UIAction(title: "Copy", identifier: UIAction.Identifier("terminal.selection.copy")) { _ in }
        ])
    }
}

struct TerminalLinkScenarioRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> TerminalLinkScenarioController {
        TerminalLinkScenarioController()
    }

    func updateUIViewController(_ controller: TerminalLinkScenarioController, context: Context) {}
}
#endif
