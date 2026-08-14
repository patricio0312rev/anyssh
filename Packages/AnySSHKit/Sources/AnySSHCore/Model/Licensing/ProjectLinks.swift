public enum ProjectLinks {
    public struct Destination: Hashable, Sendable, Identifiable {
        public let title: String
        public let subtitle: String
        public let url: String
        public let icon: String

        public var id: String { url }
    }

    public static let all: [Destination] = [
        Destination(
            title: "Website",
            subtitle: "getanyssh.com",
            url: "https://getanyssh.com",
            icon: "globe"
        ),
        Destination(
            title: "Repository",
            subtitle: "github.com/patricio0312rev/anyssh",
            url: "https://github.com/patricio0312rev/anyssh",
            icon: "chevron.left.forwardslash.chevron.right"
        ),
    ]
}
