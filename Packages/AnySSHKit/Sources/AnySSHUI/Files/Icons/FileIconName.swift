public nonisolated struct FileIconName: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let file = FileIconName("file")
    public static let folder = FileIconName("folder")
    public static let folderOpen = FileIconName("folder-open")
    public static let folderRoot = FileIconName("folder-root")
    public static let folderRootOpen = FileIconName("folder-root-open")
}
