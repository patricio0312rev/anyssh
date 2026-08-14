public enum MultiplexerNavigation: String, Hashable, Sendable {
    case previousWindow = "previous_window"
    case nextWindow = "next_window"
    case previousPane = "previous_pane"
    case nextPane = "next_pane"
}

public enum GestureBindingState: Hashable, Sendable {
    case unbound
    case bound(GestureAction)
    case unavailable(String)
}
