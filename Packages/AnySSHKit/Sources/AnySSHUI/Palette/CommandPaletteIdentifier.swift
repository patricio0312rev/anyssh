public enum CommandPaletteIdentifier {
    public static let surface = "palette.surface"
    public static let search = "palette.search"
    public static let close = "palette.close"
    public static let list = "palette.list"
    public static let empty = "palette.empty"

    public static func row(_ id: String) -> String {
        "palette.row.\(id)"
    }
}
