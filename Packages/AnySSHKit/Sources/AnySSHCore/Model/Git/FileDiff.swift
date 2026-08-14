public enum DiffLineKind: String, CaseIterable, Sendable {
    case context
    case addition
    case deletion
}

public struct DiffLine: Hashable, Sendable {
    public let kind: DiffLineKind
    public let text: String
    public let noNewlineAtEndOfFile: Bool

    public init(kind: DiffLineKind, text: String, noNewlineAtEndOfFile: Bool) {
        self.kind = kind
        self.text = text
        self.noNewlineAtEndOfFile = noNewlineAtEndOfFile
    }
}

public struct DiffHunk: Hashable, Sendable {
    public let oldStart: Int
    public let oldCount: Int
    public let newStart: Int
    public let newCount: Int
    public let heading: String
    public let lines: [DiffLine]

    public init(
        oldStart: Int,
        oldCount: Int,
        newStart: Int,
        newCount: Int,
        heading: String,
        lines: [DiffLine]
    ) {
        self.oldStart = oldStart
        self.oldCount = oldCount
        self.newStart = newStart
        self.newCount = newCount
        self.heading = heading
        self.lines = lines
    }
}

public struct FileDiff: Hashable, Sendable {
    public let file: ChangedFile
    public let hunks: [DiffHunk]
    public let isBinary: Bool
    public let truncated: Bool
    public let lossyDecode: Bool

    public init(
        file: ChangedFile,
        hunks: [DiffHunk],
        isBinary: Bool,
        truncated: Bool,
        lossyDecode: Bool
    ) {
        self.file = file
        self.hunks = hunks
        self.isBinary = isBinary
        self.truncated = truncated
        self.lossyDecode = lossyDecode
    }
}
