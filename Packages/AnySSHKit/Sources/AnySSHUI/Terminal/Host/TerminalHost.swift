#if canImport(UIKit)
import SwiftUI
import TerminalEmulator

public struct TerminalHost: View {
    private let engine: any TerminalSurfaceEngine
    private let onSessionSwitch: (() -> Void)?
    private let onGesture: ((GestureSlot) -> Void)?
    private let commandRegistry: AppCommandRegistry?
    private let keyboardLock: TerminalKeyboardLock?

    public init(
        engine: any TerminalSurfaceEngine,
        onSessionSwitch: (() -> Void)? = nil,
        onGesture: ((GestureSlot) -> Void)? = nil,
        commandRegistry: AppCommandRegistry? = nil,
        keyboardLock: TerminalKeyboardLock? = nil
    ) {
        self.engine = engine
        self.onSessionSwitch = onSessionSwitch
        self.onGesture = onGesture
        self.commandRegistry = commandRegistry
        self.keyboardLock = keyboardLock
    }

    public var body: some View {
        TerminalHostRepresentable(
            engine: engine,
            onSessionSwitch: onSessionSwitch,
            onGesture: onGesture,
            commandRegistry: commandRegistry,
            keyboardLock: keyboardLock
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct TerminalHostRepresentable: UIViewControllerRepresentable {
    let engine: any TerminalSurfaceEngine
    let onSessionSwitch: (() -> Void)?
    let onGesture: ((GestureSlot) -> Void)?
    let commandRegistry: AppCommandRegistry?
    let keyboardLock: TerminalKeyboardLock?

    func makeUIViewController(context: Context) -> TerminalHostController {
        TerminalHostController(
            engine: engine,
            onSessionSwitch: onSessionSwitch,
            onGesture: onGesture,
            commandRegistry: commandRegistry,
            keyboardLock: keyboardLock
        )
    }

    func updateUIViewController(_ controller: TerminalHostController, context: Context) {}
}
#endif
