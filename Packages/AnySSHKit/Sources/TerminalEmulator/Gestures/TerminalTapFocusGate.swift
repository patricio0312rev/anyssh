public struct TerminalTapFocusGate: Hashable, Sendable {
    private var moved = false

    public init() {}

    public mutating func touchBegan(scrollIsMoving: Bool) {
        moved = scrollIsMoving
    }

    public mutating func dragBegan() {
        moved = true
    }

    public func tapShouldFocus(keyboardLocked: Bool) -> Bool {
        !keyboardLocked && !moved
    }
}
