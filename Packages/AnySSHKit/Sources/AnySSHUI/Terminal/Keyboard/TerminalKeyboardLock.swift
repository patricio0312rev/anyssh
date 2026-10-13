import Observation

@MainActor
@Observable
public final class TerminalKeyboardLock {
    public private(set) var isLocked = false

    public init() {}

    public func lock() {
        isLocked = true
    }

    public func unlock() {
        isLocked = false
    }
}
