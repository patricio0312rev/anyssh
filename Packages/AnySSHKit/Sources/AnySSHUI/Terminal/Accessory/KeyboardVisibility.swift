#if canImport(UIKit)
import Observation
import UIKit

@Observable
@MainActor
public final class KeyboardVisibility {
    public private(set) var isVisible = false

    private var observers: [any NSObjectProtocol] = []

    public init(center: NotificationCenter = .default) {
        observers = [
            center.addObserver(
                forName: UIResponder.keyboardWillShowNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.isVisible = true }
            },
            center.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.isVisible = false }
            },
        ]
    }

    isolated deinit {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
    }
}
#endif
