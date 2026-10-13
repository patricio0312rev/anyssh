enum MuxNavigationCopy {
    static func focused(in session: String) -> String { "Focused in \(session)" }

    static func switched(to session: String) -> String { "Switched to \(session)" }

    static func jumped(to target: String) -> String { "Jumped to \(target)" }

    static func skipped(_ reason: MuxSkipReason) -> (title: String, body: String) {
        switch reason {
        case .detached:
            ("No multiplexer here", "This terminal is not inside tmux or herdr, so the swipe skipped it.")
        case .unidentified:
            (
                "Session not identified",
                "The app cannot tell which session this terminal shows, so it was left alone."
            )
        case .unreadable:
            ("Terminal not readable", "The app could not read what this terminal runs, so it was left alone.")
        case .boundElsewhere:
            ("Terminal shows another session", "That tab belongs to a session this terminal no longer shows.")
        case .timedOut:
            ("Switch took too long", "The multiplexer did not answer in time, so the swipe skipped it.")
        case .refused(let state):
            (state.copy.title, state.copy.body)
        }
    }

    static let detachToSwitch = "Detach to switch sessions."

    static let switchedSession = "Switched session"

    static let switchedTab = "Switched tab"

    static let active = "Active"
}
