public enum AgentsMenuIdentifier {
    public static let open = "agents.open"
    public static let sheet = "agents.sheet"
    public static let close = "agents.close"
    public static let failure = "agents.failure"
    public static let empty = "agents.empty"

    public static func session(_ id: String) -> String {
        "agents.session.\(id)"
    }

    public static func row(_ id: String) -> String {
        "agents.row.\(id)"
    }

    public static func status(_ id: String) -> String {
        "agents.status.\(id)"
    }

    public static func jumping(_ id: String) -> String {
        "agents.jumping.\(id)"
    }
}
