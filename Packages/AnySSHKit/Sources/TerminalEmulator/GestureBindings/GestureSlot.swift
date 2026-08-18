public enum GestureSlot: String, Codable, CaseIterable, Hashable, Sendable {
    case swipeLeft
    case swipeRight

    public var title: String {
        switch self {
        case .swipeLeft: "Swipe left"
        case .swipeRight: "Swipe right"
        }
    }
}
