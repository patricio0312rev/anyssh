import AnySSHCore

public struct GestureBindingRegistry: Sendable {
    public let layout: GestureLayout

    public init(layout: GestureLayout = .defaults) {
        self.layout = layout
    }

    public func state(for slot: GestureSlot, multiplexerAvailable: Bool = true) -> ResolvedGestureAction {
        guard let action = layout.bindings[slot.rawValue] else { return .unbound }
        switch action.kind {
        case .chord:
            guard let chord = try? Chord(parsing: action.value) else { return .unbound }
            return ResolvedGestureAction(action: .chord(chord))
        case .appCommand:
            return ResolvedGestureAction(action: .appCommand(action.value))
        case .multiplexer:
            guard multiplexerAvailable, let navigation = MultiplexerNavigation(rawValue: action.value) else {
                return ResolvedGestureAction(action: nil, reason: "Multiplexer is not available on this host")
            }
            return ResolvedGestureAction(action: .multiplexer(navigation.rawValue))
        }
    }
}
