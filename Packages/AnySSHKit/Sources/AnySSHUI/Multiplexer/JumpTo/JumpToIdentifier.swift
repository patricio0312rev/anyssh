import AnySSHCore

public enum JumpToIdentifier {
    public static let open = "jump.open"
    public static let sheet = "jump.sheet"
    public static let close = "jump.close"
    public static let title = "jump.title"
    public static let waiting = "jump.waiting"
    public static let explanation = "jump.explanation"
    public static let bytes = "jump.bytes"
    public static let layoutList = "jump.layout.list"
    public static let layoutAccordion = "jump.layout.accordion"
    public static let layoutGrid = "jump.layout.grid"

    public static func group(_ id: String) -> String {
        "jump.group.\(id)"
    }

    public static func row(_ id: String) -> String {
        "jump.row.\(id)"
    }

    public static func status(_ id: String) -> String {
        "jump.status.\(id)"
    }

    public static func card(_ id: String) -> String {
        "jump.card.\(id)"
    }

    public static func chip(_ id: String) -> String {
        "jump.chip.\(id)"
    }
}
