public struct ModifierLatch: Hashable, Sendable {
    public enum State: Hashable, Sendable {
        case off
        case oneShot
        case locked

        var next: State {
            switch self {
            case .off: .oneShot
            case .oneShot: .locked
            case .locked: .off
            }
        }

        var isActive: Bool {
            self != .off
        }
    }

    public private(set) var control = State.off
    public private(set) var alt = State.off
    public private(set) var shift = State.off

    public init() {}

    public subscript(modifier: LatchedModifier) -> State {
        switch modifier {
        case .control: control
        case .alt: alt
        case .shift: shift
        }
    }

    public var pending: KeyModifiers {
        var modifiers = KeyModifiers()
        for modifier in LatchedModifier.allCases where self[modifier].isActive {
            modifiers.insert(modifier.keyModifier)
        }
        return modifiers
    }

    public var isEmpty: Bool {
        pending.isEmpty
    }

    @discardableResult
    public mutating func tap(_ modifier: LatchedModifier) -> State {
        let state = self[modifier].next
        set(modifier, to: state)
        return state
    }

    public mutating func consume() -> KeyModifiers {
        let modifiers = pending
        for modifier in LatchedModifier.allCases where self[modifier] == .oneShot {
            set(modifier, to: .off)
        }
        return modifiers
    }

    public mutating func clear() {
        control = .off
        alt = .off
        shift = .off
    }

    private mutating func set(_ modifier: LatchedModifier, to state: State) {
        switch modifier {
        case .control: control = state
        case .alt: alt = state
        case .shift: shift = state
        }
    }
}

public enum LatchedModifier: CaseIterable, Hashable, Sendable {
    case control
    case alt
    case shift

    public var keyModifier: KeyModifiers {
        switch self {
        case .control: .control
        case .alt: .alt
        case .shift: .shift
        }
    }
}
