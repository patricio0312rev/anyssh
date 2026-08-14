#if canImport(UIKit)
import SwiftUI
import TerminalEmulator

public struct TerminalHost: View {
    private let engine: any TerminalSurfaceEngine
    private let onSessionSwitch: (() -> Void)?
    private let onGesture: ((GestureSlot) -> Void)?
    private let commandRegistry: AppCommandRegistry?

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
    }

    public var body: some View {
        TerminalHostRepresentable(
            engine: engine,
            onSessionSwitch: onSessionSwitch,
            onGesture: onGesture,
            commandRegistry: commandRegistry
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct TerminalHostRepresentable: UIViewControllerRepresentable {
    let engine: any TerminalSurfaceEngine
    let onSessionSwitch: (() -> Void)?
    let onGesture: ((GestureSlot) -> Void)?
    let commandRegistry: AppCommandRegistry?

    func makeUIViewController(context: Context) -> TerminalHostController {
        TerminalHostController(
            engine: engine,
            onSessionSwitch: onSessionSwitch,
            onGesture: onGesture,
            commandRegistry: commandRegistry
        )
    }

    func updateUIViewController(_ controller: TerminalHostController, context: Context) {}
}
#endif
