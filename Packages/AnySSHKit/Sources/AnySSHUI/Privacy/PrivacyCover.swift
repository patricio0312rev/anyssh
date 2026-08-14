#if canImport(UIKit)
import SwiftUI
import UIKit

public struct PrivacyCover: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @State private var window = PrivacyCoverWindow()
    @State private var scene: UIWindowScene?

    public func body(content: Content) -> some View {
        content
            .background(PrivacyCoverSceneReader { scene = $0 })
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    window.hide()
                } else {
                    window.show(on: scene)
                }
            }
    }
}

extension View {
    public func privacyCover() -> some View {
        modifier(PrivacyCover())
    }
}

private struct PrivacyCoverSceneReader: UIViewRepresentable {
    let onResolve: (UIWindowScene) -> Void

    func makeUIView(context: Context) -> ReaderView { ReaderView(onResolve: onResolve) }

    func updateUIView(_ uiView: ReaderView, context: Context) {}

    final class ReaderView: UIView {
        private let onResolve: (UIWindowScene) -> Void

        init(onResolve: @escaping (UIWindowScene) -> Void) {
            self.onResolve = onResolve
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("PrivacyCoverSceneReader.ReaderView is never restored from a coder")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let scene = window?.windowScene { onResolve(scene) }
        }
    }
}
#endif
