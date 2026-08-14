#if canImport(UIKit)
import UIKit

@MainActor
final class TerminalScrollArbitration {
    private weak var scrollView: UIScrollView?
    private var savedScrollEnabled: Bool?

    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
    }

    func disableForSelection() {
        guard let scrollView, savedScrollEnabled == nil else { return }
        savedScrollEnabled = scrollView.isScrollEnabled
        scrollView.isScrollEnabled = false
    }

    func restore() {
        guard let savedScrollEnabled, let scrollView else { return }
        scrollView.isScrollEnabled = savedScrollEnabled
        self.savedScrollEnabled = nil
    }

    func restoreIfIdle(gestureIsActive: Bool) {
        guard !gestureIsActive else { return }
        restore()
    }
}
#endif
