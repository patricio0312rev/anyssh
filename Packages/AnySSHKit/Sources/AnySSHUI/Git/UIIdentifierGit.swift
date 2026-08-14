extension UIIdentifier {
    public enum Changes {
        public static let header = "git.changes.header"
        public static let list = "git.changes.list"
        public static let clean = "git.changes.clean"
        public static let loading = "git.changes.loading"
        public static let openHistory = "git.history.open"

        public static func file(_ section: String, _ index: Int) -> String {
            "git.changes.\(section).\(index)"
        }
    }

    public enum History {
        public static let screen = "git.history"
        public static let loading = "git.history.loading"
        public static let empty = "git.history.empty"
        public static let list = "git.history.list"
        public static let detail = "git.history.detail"
        public static let firstParent = "git.history.firstParent"
        public static let copySHA = "git.history.copy.sha"
        public static let copyAuthor = "git.history.copy.author"
        public static let copyEmail = "git.history.copy.email"
        public static let copyDate = "git.history.copy.date"
        public static let close = "git.history.close"

        public static func row(_ id: String) -> String {
            "git.history.row.\(id)"
        }

        public static func file(_ index: Int) -> String {
            "git.commit.file.\(index)"
        }
    }

    public enum Diff {
        public static let renderer = "git.diff.renderer"
        public static let detail = "git.diff.detail"

        public static func row(_ id: String) -> String {
            "git.diff.row.\(id)"
        }
    }
}
