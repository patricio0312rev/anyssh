enum MuxNavigationCopy {
    static func focused(in session: String) -> String { "Focused in \(session)" }

    static func switched(to session: String) -> String { "Switched to \(session)" }

    static func jumped(to target: String) -> String { "Jumped to \(target)" }

    static let detachToSwitch = "Detach to switch sessions."

    static let currentSession = "this session"

    static let switchedSession = "Switched session"

    static let switchedTab = "Switched tab"

    static let active = "Active"
}
