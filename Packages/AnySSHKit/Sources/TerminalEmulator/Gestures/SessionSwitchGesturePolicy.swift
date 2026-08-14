public enum SwipeDirection: String, Hashable, Sendable {
    case up
    case down
    case left
    case right

    public var isHorizontal: Bool { self == .left || self == .right }
}

public enum SessionSwitchGesturePolicy {
    public static let minimumTravel: Double = 44

    public static let axisMargin: Double = 1.6

    public static func accepts(touchCount: Int) -> Bool {
        touchCount == 2
    }

    public static func direction(dx: Double, dy: Double) -> SwipeDirection? {
        let horizontal = abs(dx)
        let vertical = abs(dy)
        if horizontal >= minimumTravel && horizontal > vertical * axisMargin {
            return dx < 0 ? .left : .right
        }
        if vertical >= minimumTravel && vertical > horizontal * axisMargin {
            return dy < 0 ? .up : .down
        }
        return nil
    }

    public static func isSideways(velocityX: Double, velocityY: Double) -> Bool {
        abs(velocityX) > abs(velocityY) * axisMargin
    }

    public static func slot(_ direction: SwipeDirection, fingers: Int) -> GestureSlot {
        switch (direction, fingers) {
        case (.up, 1): return .swipeUp
        case (.down, 1): return .swipeDown
        case (.left, 1): return .swipeLeft
        case (.right, 1): return .swipeRight
        case (.up, _): return .twoFingerSwipeUp
        case (.down, _): return .twoFingerSwipeDown
        case (.left, _): return .twoFingerSwipeLeft
        case (.right, _): return .twoFingerSwipeRight
        }
    }
}
