#if canImport(UIKit)
import SwiftUI
import UIKit

struct TerminalKeyboardToggle: View {
    let engine: any TerminalSurfaceEngine
    @State private var keyboardVisible = false

    var body: some View {
        Button(action: toggle) {
            Image(systemName: keyboardVisible ? "keyboard.chevron.compact.down" : "keyboard")
        }
        .accessibilityLabel(keyboardVisible ? "Hide keyboard" : "Show keyboard")
        .accessibilityIdentifier(UIIdentifier.Terminal.dismissKeyboard)
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
            engine.wantsKeyboard = false
            _ = engine.surface.resignFirstResponder()
        } else {
            engine.wantsKeyboard = true
            _ = engine.surface.becomeFirstResponder()
        }
    }
}
#endif
