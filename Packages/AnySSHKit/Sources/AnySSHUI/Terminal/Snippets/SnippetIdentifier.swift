public enum SnippetIdentifier {
    public static let sheet = "snippets.sheet"
    public static let close = "snippets.close"
    public static let newTitle = "snippets.newTitle"
    public static let newBody = "snippets.newBody"
    public static let save = "snippets.save"

    public static func row(_ id: String) -> String { "snippets.row.\(id)" }
}
