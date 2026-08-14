import Foundation

public enum FileTreeEntryKind: String, Sendable, Hashable {
    case file
    case directory
    case symlink
    case submodule
    case other
}

public struct FileTreeEntry: Sendable, Hashable {
    public let mode: String
    public let kind: FileTreeEntryKind
    public let objectID: String
    public let path: String

    public init(mode: String, kind: FileTreeEntryKind, objectID: String, path: String) {
        self.mode = mode
        self.kind = kind
        self.objectID = objectID
        self.path = path
    }
}

public struct FileTree: Sendable, Hashable {
    public let entries: [FileTreeEntry]

    public init(entries: [FileTreeEntry]) {
        self.entries = entries
    }
}

public enum BlobRefKind: Sendable, Hashable {
    case workingTree
    case commit(String)
}
