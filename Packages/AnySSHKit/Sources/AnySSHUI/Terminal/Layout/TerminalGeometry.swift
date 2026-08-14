#if canImport(UIKit)
import CoreGraphics
import UIKit

public struct TerminalGeometry: Equatable, Sendable {
    public var bounds: CGRect
    public var safeAreaInsets: UIEdgeInsets
    public var keyboardOverlap: CGFloat

    public init(
        bounds: CGRect,
        safeAreaInsets: UIEdgeInsets,
        keyboardOverlap: CGFloat = 0
    ) {
        self.bounds = bounds
        self.safeAreaInsets = safeAreaInsets
        self.keyboardOverlap = max(0, keyboardOverlap)
    }

    public var surfaceFrame: CGRect {
        let left = safeAreaInsets.left
        let right = safeAreaInsets.right
        let top = safeAreaInsets.top
        let bottom = max(safeAreaInsets.bottom, keyboardOverlap)
        let width = max(0, bounds.width - left - right)
        let height = max(0, bounds.height - top - bottom)
        return CGRect(x: left, y: top, width: width, height: height)
    }

    public func respectsHorizontalSafeArea() -> Bool {
        let frame = surfaceFrame
        return frame.minX >= safeAreaInsets.left - .ulpOfOne
            && frame.maxX <= bounds.width - safeAreaInsets.right + .ulpOfOne
    }
}

public enum IPhone17ProLandscape {
    public static let bounds = CGRect(x: 0, y: 0, width: 874, height: 402)
    public static let safeAreaInsets = UIEdgeInsets(top: 0, left: 62, bottom: 21, right: 62)

    public static var geometry: TerminalGeometry {
        TerminalGeometry(bounds: bounds, safeAreaInsets: safeAreaInsets)
    }
}
#endif
