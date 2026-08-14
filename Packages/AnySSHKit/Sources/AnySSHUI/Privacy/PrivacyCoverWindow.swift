#if canImport(UIKit)
import SwiftUI
import UIKit

@MainActor
final class PrivacyCoverWindow {
    private var window: UIWindow?

    func show(on hostingScene: UIWindowScene?) {
        guard window == nil, let scene = hostingScene ?? Self.foregroundScene() else { return }
        let host = UIHostingController(rootView: PrivacyCoverView())
        host.view.backgroundColor = .clear
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.isUserInteractionEnabled = false
        window.rootViewController = host
        window.isHidden = false
        self.window = window
    }

    func hide() {
        window?.isHidden = true
        window = nil
    }

    private static func foregroundScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.windows.contains(where: \.isKeyWindow) } ?? scenes.first
    }
}
#endif
