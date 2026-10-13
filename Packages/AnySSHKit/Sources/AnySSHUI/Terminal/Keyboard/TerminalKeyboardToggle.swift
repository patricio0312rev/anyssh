#if canImport(UIKit)
import SwiftUI
import UIKit

struct TerminalKeyboardToggle: View {
    let engine: any TerminalSurfaceEngine
    let lock: TerminalKeyboardLock
    @State private var keyboardVisible = false

    var body: some View {
        IconButton(
            systemImage: keyboardVisible ? "keyboard.chevron.compact.down" : "keyboard",
            label: keyboardVisible ? "Hide keyboard" : "Show keyboard",
            surface: .toolbar,
            accessibilityIdentifier: UIIdentifier.Terminal.dismissKeyboard,
            action: toggle
        )
        .onReceive(keyboardWillShow) { _ in keyboardVisible = true }
        .onReceive(keyboardWillHide) { _ in keyboardVisible = false }
    }

    private var keyboardWillShow: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
    }

    private var keyboardWillHide: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
    }

    private func toggle() {
        if engine.surface.isFirstResponder {
            lock.lock()
            engine.wantsKeyboard = false
            _ = engine.surface.resignFirstResponder()
        } else {
            lock.unlock()
            engine.wantsKeyboard = true
            _ = engine.surface.becomeFirstResponder()
        }
    }
}
#endif
