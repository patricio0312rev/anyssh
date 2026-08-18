#if canImport(UIKit)
import TerminalEmulator
import UIKit

extension TerminalHostController {
    func observeKeyboardForBarInset() {
        let center = NotificationCenter.default
        keyboardObservers = [
            center.addObserver(
                forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.setBarInset(AccessoryBarMetrics.height) }
            },
            center.addObserver(
                forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.setBarInset(0) }
            },
        ]
    }

    func setBarInset(_ inset: CGFloat) {
        surfaceBottom?.constant = -inset
        view.layoutIfNeeded()
    }

    func installHardwareKeyboard() {
        let keyboard = HardwareKeyboardView()
        keyboard.translatesAutoresizingMaskIntoConstraints = false
        keyboard.isUserInteractionEnabled = false
        keyboard.registry = commandRegistry
        keyboard.onTransport = { [weak engine] bytes in
            engine?.emitInput(bytes[...])
        }
        view.addSubview(keyboard)
        let guides = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            keyboard.topAnchor.constraint(equalTo: guides.topAnchor),
            keyboard.leadingAnchor.constraint(equalTo: guides.leadingAnchor),
            keyboard.trailingAnchor.constraint(equalTo: guides.trailingAnchor),
            keyboard.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
        ])
        let probes = HardwareKeyboardProbe.install(on: view, session: { keyboard.session })
        shortcutProbe = probes.shortcutLog
        transportProbe = probes.transportBytes
        keyboard.didRoutePress = { [weak self] session in
            guard let self,
                let shortcut = self.shortcutProbe,
                let transport = self.transportProbe
            else {
                return
            }
            HardwareKeyboardProbe.refresh(
                shortcutLog: shortcut,
                transportBytes: transport,
                session: session
            )
        }
        keyboardView = keyboard
    }

    func observeKeyboardReclaim() {
        reclaimObserver = NotificationCenter.default.addObserver(
            forName: .anySSHReclaimHardwareKeyboard,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.keyboardView?.becomeFirstResponder()
        }
    }

    func installInteractionIfNeeded() {
        guard let swiftTerm = engine as? SwiftTermEngine else { return }
        let bridge =
            (swiftTerm.gestureBridge as? TerminalGestureBridge)
            ?? {
                let created = TerminalGestureBridge(view: swiftTerm.view)
                created.install()
                swiftTerm.gestureBridge = created
                return created
            }()
        bridge.onSessionSwitch = onSessionSwitch
        bridge.onGesture = onGesture
        bridge.onMouseReport = { [weak swiftTerm] bytes in
            swiftTerm?.emitInput(bytes[...])
        }
        bridge.onKeyBytes = { [weak swiftTerm] bytes in
            swiftTerm?.emitInput(bytes[...])
        }
        bridge.onCopy = { text in
            SystemClipboardPasteboard().write(text)
        }
        bridge.onFocus = { [weak swiftTerm] in
            swiftTerm?.wantsKeyboard = true
        }
        gestureBridge = bridge
        didInstallInteraction = true
    }
}
#endif
