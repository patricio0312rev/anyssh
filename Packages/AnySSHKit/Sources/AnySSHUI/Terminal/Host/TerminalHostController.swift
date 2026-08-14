#if canImport(UIKit)
import TerminalEmulator
import UIKit

public final class TerminalHostController: UIViewController {
    let engine: any TerminalSurfaceEngine
    let onSessionSwitch: (() -> Void)?
    let onGesture: ((GestureSlot) -> Void)?
    let commandRegistry: AppCommandRegistry?
    var gestureBridge: TerminalGestureBridge?
    var didInstallInteraction = false
    var keyboardView: HardwareKeyboardView?
    var surfaceBottom: NSLayoutConstraint?
    var keyboardObservers: [any NSObjectProtocol] = []
    var shortcutProbe: UILabel?
    var transportProbe: UILabel?
    var reclaimObserver: NSObjectProtocol?

    public init(
        engine: any TerminalSurfaceEngine,
        onSessionSwitch: (() -> Void)? = nil,
        onGesture: ((GestureSlot) -> Void)? = nil,
        commandRegistry: AppCommandRegistry? = nil
    ) {
        self.engine = engine
        self.onSessionSwitch = onSessionSwitch
        self.onGesture = onGesture
        self.commandRegistry = commandRegistry
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        preconditionFailure("TerminalHostController is created in code, never from a nib")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MonokaiProPalette.windowBackground
        view.keyboardLayoutGuide.followsUndockedKeyboard = true
        attachSurface()
        installHardwareKeyboard()
        observeKeyboardForBarInset()
        observeKeyboardReclaim()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        attachSurface()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        engine.activateRenderer()
        view.layoutIfNeeded()
        engine.surface.layoutTerminalNow()
        installInteractionIfNeeded()
        keyboardView?.becomeFirstResponder()
    }

    isolated deinit {
        if let reclaimObserver {
            NotificationCenter.default.removeObserver(reclaimObserver)
        }
    }

    private func attachSurface() {
        let surface = engine.surface
        guard surface.superview !== view else { return }
        let wasFirstResponder = surface.isFirstResponder || engine.wantsKeyboard
        if wasFirstResponder {
            surface.resignFirstResponder()
        }
        surface.removeFromSuperview()
        surface.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(surface)
        let guides = view.safeAreaLayoutGuide
        let surfaceBottom = surface.bottomAnchor.constraint(
            equalTo: view.keyboardLayoutGuide.topAnchor
        )
        self.surfaceBottom = surfaceBottom
        NSLayoutConstraint.activate([
            surface.topAnchor.constraint(equalTo: guides.topAnchor),
            surface.leadingAnchor.constraint(equalTo: guides.leadingAnchor),
            surface.trailingAnchor.constraint(equalTo: guides.trailingAnchor),
            surfaceBottom,
        ])
        if wasFirstResponder {
            _ = surface.becomeFirstResponder()
        }
    }
}
#endif
