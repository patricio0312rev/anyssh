public enum FileChange: Hashable, Sendable {
    case added
    case modified
    case deleted
    case renamed(similarity: Int)
    case copied(similarity: Int)
    case typeChanged
    case unmerged

    public var isRename: Bool {
        if case .renamed = self { return true }
        return false
    }
}

public struct ChangedFile: Hashable, Sendable {
    public let oldPath: String?
    public let newPath: String?
    public let change: FileChange
    public let isBinary: Bool
    public let additions: Int
    public let deletions: Int

    public init(
        oldPath: String?,
        newPath: String?,
        change: FileChange,
        isBinary: Bool,
        additions: Int = 0,
        deletions: Int = 0
    ) {
        self.oldPath = oldPath
        self.newPath = newPath
        self.change = change
        self.isBinary = isBinary
        self.additions = additions
        self.deletions = deletions
    }
}

extension ChangedFile {
    public var pathspec: [String] {
        if change.isRename {
            guard let newPath, let oldPath else {
                preconditionFailure("a rename that names one side is a malformed model")
            }
            return [newPath, oldPath]
        }
        guard let path = newPath ?? oldPath else {
            preconditionFailure("a changed file that names no path is a malformed model")
        }
        return [path]
    }
}
