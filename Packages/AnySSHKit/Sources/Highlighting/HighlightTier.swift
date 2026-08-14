import AnySSHCore

public enum HighlightTier: String, CaseIterable, Sendable {
    case rowTintOnly
    case wholeBlob
    case hunkOnly
}

public struct BlobSide: Sendable, Hashable {
    public let sha: String
    public let text: String

    public init(sha: String, text: String) {
        self.sha = sha
        self.text = text
    }
}

public struct DiffSides: Sendable, Hashable {
    public let old: BlobSide?
    public let new: BlobSide?

    public init(old: BlobSide?, new: BlobSide?) {
        self.old = old
        self.new = new
    }
}

public struct HighlightedHunk: Sendable, Hashable {
    public let tier: HighlightTier
    public let rows: [LineTokens]

    public init(tier: HighlightTier, rows: [LineTokens]) {
        self.tier = tier
        self.rows = rows
    }
}

public enum HighlightPolicy {
    public static let blobByteCap = 256 * 1024

    public static func neededSides(for hunk: DiffHunk) -> (old: Bool, new: Bool) {
        var old = false
        var new = false
        for line in hunk.lines {
            switch line.kind {
            case .context:
                old = true
                new = true
            case .addition: new = true
            case .deletion: old = true
            }
        }
        return (old, new)
    }

    public static func tier(for hunk: DiffHunk, sides: DiffSides, language: LanguageID)
        -> HighlightTier
    {
        guard TreeSitterGrammar(language) != nil else { return .rowTintOnly }
        let needed = neededSides(for: hunk)
        if needed.old, usable(sides.old) == false { return .hunkOnly }
        if needed.new, usable(sides.new) == false { return .hunkOnly }
        return .wholeBlob
    }

    private static func usable(_ side: BlobSide?) -> Bool {
        guard let side else { return false }
        return side.text.utf8.count <= blobByteCap
    }
}
