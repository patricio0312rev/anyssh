public enum SessionSwitcherIdentifier {
    public static let surface = "session.switcher"
    public static let newSession = "session.switcher.newSession"
    public static let mode = "session.switcher.mode"
    public static let empty = "session.empty"
    public static let close = "session.switcher.close"
    public static let title = "session.title"
    public static let byteCounter = "session.byteCounter"

    public static func row(_ id: String) -> String {
        "session.row.\(id)"
    }

    public static func closeRow(_ id: String) -> String {
        "session.row.\(id).close"
    }
}
