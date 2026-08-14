import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

public struct ClipboardPasteControl: View {
    private let onPaste: () -> Void

    public init(onPaste: @escaping () -> Void) {
        self.onPaste = onPaste
    }

    public var body: some View {
        #if canImport(UIKit)
        PasteControlRepresentable(onPaste: onPaste)
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityIdentifier(UIIdentifier.Terminal.Clipboard.pasteControl)
        #else
        Button("Paste", action: onPaste)
            .accessibilityIdentifier(UIIdentifier.Terminal.Clipboard.pasteControl)
        #endif
    }
}

#if canImport(UIKit)
private struct PasteControlRepresentable: UIViewRepresentable {
    let onPaste: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPaste: onPaste)
    }

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Paste", for: .normal)
        button.accessibilityIdentifier = UIIdentifier.Terminal.Clipboard.pasteControl
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: UIButton, context: Context) {
        context.coordinator.onPaste = onPaste
    }

    final class Coordinator: NSObject {
        var onPaste: () -> Void

        init(onPaste: @escaping () -> Void) {
            self.onPaste = onPaste
        }

        @objc func tapped() {
            onPaste()
        }
    }
}
#endif
