public enum GestureActionCatalogue {
    public struct Action: Hashable, Sendable, Identifiable {
        public let kind: GestureLayout.Binding.Kind
        public let value: String
        public let title: String
        public let group: String

        public var id: String { "\(kind.rawValue).\(value)" }
    }

    public static let all: [Action] = [
        Action(kind: .appCommand, value: "paste", title: "Paste", group: "Terminal"),
        Action(
            kind: .appCommand, value: "change_font_size", title: "Change text size", group: "Terminal"
        ),
        Action(kind: .chord, value: "escape", title: "Send Escape", group: "Terminal"),
        Action(kind: .appCommand, value: "session.previous", title: "Previous session", group: "Sessions"),
        Action(kind: .appCommand, value: "session.next", title: "Next session", group: "Sessions"),
        Action(kind: .appCommand, value: "view.terminal", title: "Show the terminal", group: "Screens"),
        Action(kind: .appCommand, value: "view.changes", title: "Show changes", group: "Screens"),
        Action(kind: .appCommand, value: "open_changes", title: "Open changes", group: "Screens"),
        Action(kind: .appCommand, value: "close_changes", title: "Close changes", group: "Screens"),
        Action(
            kind: .multiplexer, value: "previous_pane", title: "Previous pane", group: "Multiplexer"
        ),
        Action(kind: .multiplexer, value: "next_pane", title: "Next pane", group: "Multiplexer"),
        Action(kind: .multiplexer, value: "next_window", title: "Next window", group: "Multiplexer"),
    ]

    public static let groups = ["Terminal", "Sessions", "Screens", "Multiplexer"]

    public static func actions(in group: String) -> [Action] {
        all.filter { $0.group == group }
    }

    public static func title(of binding: GestureLayout.Binding?) -> String {
        guard let binding else { return "Unbound" }
        let match = all.first { $0.kind == binding.kind && $0.value == binding.value }
        return match?.title ?? binding.value
    }
}
