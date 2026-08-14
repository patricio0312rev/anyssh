public enum GestureSlot: String, Codable, CaseIterable, Hashable, Sendable {
    case tap
    case doubleTap
    case tripleTap
    case swipeUp
    case swipeDown
    case swipeLeft
    case swipeRight
    case twoFingerSwipeUp
    case twoFingerSwipeDown
    case twoFingerSwipeLeft
    case twoFingerSwipeRight
    case pinch
    case headerSoftDrag
    case headerHardDrag
    case dPadTopLeft
    case dPadBottomRight

    public var title: String {
        switch self {
        case .tap: "Tap"
        case .doubleTap: "Double-tap"
        case .tripleTap: "Triple-tap"
        case .swipeUp: "Swipe up"
        case .swipeDown: "Swipe down"
        case .swipeLeft: "Swipe left"
        case .swipeRight: "Swipe right"
        case .twoFingerSwipeUp: "Two-finger swipe up"
        case .twoFingerSwipeDown: "Two-finger swipe down"
        case .twoFingerSwipeLeft: "Two-finger swipe left"
        case .twoFingerSwipeRight: "Two-finger swipe right"
        case .pinch: "Pinch"
        case .headerSoftDrag: "Header soft drag"
        case .headerHardDrag: "Header hard drag"
        case .dPadTopLeft: "D-pad top left"
        case .dPadBottomRight: "D-pad bottom right"
        }
    }
}
