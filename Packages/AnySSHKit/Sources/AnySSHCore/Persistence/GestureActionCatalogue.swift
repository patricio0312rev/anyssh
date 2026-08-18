public enum GestureActionCatalogue {
    public struct Action: Hashable, Sendable, Identifiable {
        public let kind: GestureLayout.Binding.Kind
        public let value: String
        public let title: String
        public let group: String

        public var id: String { "\(kind.rawValue).\(value)" }
    }

    public static let all: [Action] = [
        Action(kind: .appCommand, value: "session.previous", title: "Previous session", group: "Sessions"),
        Action(kind: .appCommand, value: "session.next", title: "Next session", group: "Sessions"),
    ]

    public static let groups = ["Sessions"]

    public static func actions(in group: String) -> [Action] {
        all.filter { $0.group == group }
    }

    public static func title(of binding: GestureLayout.Binding?) -> String {
        guard let binding else { return "Unbound" }
        let match = all.first { $0.kind == binding.kind && $0.value == binding.value }
        return match?.title ?? binding.value
    }
}
