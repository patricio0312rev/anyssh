#if canImport(UIKit)
import CoreGraphics
@preconcurrency import UIKit

@MainActor
public final class TerminalPinchFontController: NSObject, UIGestureRecognizerDelegate {
    public typealias CommitHandler = @MainActor (CGFloat) -> Void

    public private(set) var committedSize: CGFloat
    public private(set) var previewSize: CGFloat
    public private(set) var transportResizeCount = 0
    public private(set) var intermediateScaleCount = 0

    private let store: TerminalFontSizeStore
    private let onCommit: CommitHandler
    private var baseSize: CGFloat = 0
    private weak var recognizer: UIPinchGestureRecognizer?

    public init(
        store: TerminalFontSizeStore = TerminalFontSizeStore(),
        onCommit: @escaping CommitHandler = { _ in }
    ) {
        let size = store.load()
        self.store = store
        self.onCommit = onCommit
        committedSize = size
        previewSize = size
    }

    @discardableResult
    public func install(on view: UIView) -> UIPinchGestureRecognizer {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        pinch.delegate = self
        view.addGestureRecognizer(pinch)
        recognizer = pinch
        return pinch
    }

    public func apply(scale: CGFloat, state: UIGestureRecognizer.State) {
        switch state {
        case .began:
            baseSize = committedSize
            intermediateScaleCount = 0
            previewSize = TerminalFontSizeStore.size(base: baseSize, scale: scale)
        case .changed:
            intermediateScaleCount += 1
            previewSize = TerminalFontSizeStore.size(base: baseSize, scale: scale)
        case .ended:
            let next = TerminalFontSizeStore.size(base: baseSize, scale: scale)
            commit(next)
        case .cancelled, .failed:
            previewSize = committedSize
        default:
            break
        }
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        false
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        apply(scale: gesture.scale, state: gesture.state)
    }

    private func commit(_ size: CGFloat) {
        guard size != committedSize else {
            previewSize = committedSize
            return
        }
        committedSize = size
        previewSize = size
        store.save(size)
        transportResizeCount += 1
        onCommit(size)
    }
}
#endif
