public enum TerminalGestureRoute: String, CaseIterable, Hashable, Sendable {
    case scrollback
    case remoteApp
    case remoteKeys
    case selection
}

public struct TerminalGestureMode: Hashable, Sendable {
    public let alternateScreen: Bool
    public let mouseReporting: Bool
    public let touchMode: Bool
    public let shiftHeld: Bool

    public init(
        alternateScreen: Bool,
        mouseReporting: Bool,
        touchMode: Bool,
        shiftHeld: Bool
    ) {
        self.alternateScreen = alternateScreen
        self.mouseReporting = mouseReporting
        self.touchMode = touchMode
        self.shiftHeld = shiftHeld
    }
}

public enum TerminalGesturePolicy {
    public static func route(for mode: TerminalGestureMode) -> TerminalGestureRoute {
        if mode.shiftHeld {
            return .selection
        }
        if mode.mouseReporting && !mode.touchMode {
            return .remoteApp
        }
        if mode.alternateScreen && !mode.touchMode {
            return .remoteKeys
        }
        return .scrollback
    }

    public static func dragShouldBegin(route: TerminalGestureRoute, selectionActive: Bool) -> Bool {
        true
    }

    public static func shouldReportClick(route: TerminalGestureRoute, didTravel: Bool) -> Bool {
        route == .remoteApp && !didTravel
    }
}
