enum MuxNavigationCopy {
    static func focused(in session: String) -> String { "Focused in \(session)" }

    static func switched(to session: String) -> String { "Switched to \(session)" }

    static let detachToSwitch = "Detach to switch sessions."

    static let currentSession = "this session"
}
