public struct DirectoryEntry: Hashable, Sendable, Identifiable {
    public enum Kind: String, Hashable, Sendable {
        case directory
        case file
        case symlink
    }

    public let name: String
    public let kind: Kind

    public var id: String { name }
    public var isDirectory: Bool { kind == .directory }

    public init(name: String, kind: Kind) {
        self.name = name
        self.kind = kind
    }
}

public struct DirectoryListing: Hashable, Sendable {
    public let path: String
    public let entries: [DirectoryEntry]
    public let isTruncated: Bool

    public init(path: String, entries: [DirectoryEntry], isTruncated: Bool = false) {
        self.path = path
        self.entries = entries.sorted {
            if $0.isDirectory != $1.isDirectory { return $0.isDirectory }
            return $0.name.lowercased() < $1.name.lowercased()
        }
        self.isTruncated = isTruncated
    }
}
