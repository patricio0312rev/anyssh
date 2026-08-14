#if canImport(UIKit)
import TerminalEmulator
@preconcurrency import UIKit

extension Notification.Name {
    static let anySSHReclaimHardwareKeyboard = Notification.Name("anySSH.reclaimHardwareKeyboard")
}

@MainActor
public final class HardwareKeyboardView: UIView {
    public var session = HardwareKeyboardSession()
    public var onTransport: (([UInt8]) -> Void)?
    public var registry: AppCommandRegistry?
    public var didRoutePress: ((HardwareKeyboardSession) -> Void)?

    public override var canBecomeFirstResponder: Bool { true }

    private static let arrows: [(String, TerminalKey)] = [
        (UIKeyCommand.inputUpArrow, .up),
        (UIKeyCommand.inputDownArrow, .down),
        (UIKeyCommand.inputLeftArrow, .left),
        (UIKeyCommand.inputRightArrow, .right),
    ]

    public override var keyCommands: [UIKeyCommand]? {
        arrowCommands + registryCommands
    }

    private var arrowCommands: [UIKeyCommand] {
        Self.arrows.map { input, _ in
            let command = UIKeyCommand(
                input: input,
                modifierFlags: [],
                action: #selector(performArrow(_:))
            )
            command.wantsPriorityOverSystemBehavior = true
            return command
        }
    }

    @objc
    private func performArrow(_ sender: UIKeyCommand) {
        guard let input = sender.input,
            let key = Self.arrows.first(where: { $0.0 == input })?.1
        else {
            return
        }
        let before = session.transportBytes.count
        session.send(key)
        let written = Array(session.transportBytes.dropFirst(before))
        if !written.isEmpty { onTransport?(written) }
        didRoutePress?(session)
    }

    private var registryCommands: [UIKeyCommand] {
        (registry?.commands ?? []).compactMap { command -> UIKeyCommand? in
            guard let equivalent = command.keyEquivalent, let input = equivalent.input else {
                return nil
            }
            return UIKeyCommand(
                title: command.title,
                image: nil,
                action: #selector(performCommand(_:)),
                input: input,
                modifierFlags: equivalent.uiModifierFlags,
                propertyList: command.id
            )
        }
    }

    @objc
    private func performCommand(_ sender: UIKeyCommand) {
        guard let id = sender.propertyList as? String else { return }
        registry?.run(id: id)
    }

    public override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var consumed = Set<UIPress>()
        for press in presses {
            guard let key = press.key else { continue }
            let flags = key.modifierFlags
            let before = session.transportBytes.count
            let route = session.press(
                keyCode: UInt16(key.keyCode.rawValue),
                control: flags.contains(.control),
                alt: flags.contains(.alternate),
                shift: flags.contains(.shift),
                command: flags.contains(.command)
            )
            switch route {
            case .transport:
                consumed.insert(press)
                let written = Array(session.transportBytes.dropFirst(before))
                if !written.isEmpty { onTransport?(written) }
            case .appShortcut, .ignore:
                break
            }
        }
        let remaining = presses.subtracting(consumed)
        if !remaining.isEmpty {
            super.pressesBegan(remaining, with: event)
        }
        didRoutePress?(session)
    }

    public override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        session.pressesEnded()
        super.pressesEnded(presses, with: event)
    }
}
#endif
