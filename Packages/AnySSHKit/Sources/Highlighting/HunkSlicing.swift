import AnySSHCore

public enum HunkSlicing {
    public static func rows(for hunk: DiffHunk, old: [LineTokens], new: [LineTokens])
        -> [LineTokens]
    {
        var oldLine = hunk.oldStart
        var newLine = hunk.newStart
        var rows: [LineTokens] = []
        rows.reserveCapacity(hunk.lines.count)

        for line in hunk.lines {
            switch line.kind {
            case .context:
                rows.append(tokens(new, at: newLine) ?? tokens(old, at: oldLine) ?? empty)
                oldLine += 1
                newLine += 1
            case .addition:
                rows.append(tokens(new, at: newLine) ?? empty)
                newLine += 1
            case .deletion:
                rows.append(tokens(old, at: oldLine) ?? empty)
                oldLine += 1
            }
        }
        return rows
    }

    public static func text(of hunk: DiffHunk) -> String {
        hunk.lines.map(\.text).joined(separator: "\n")
    }

    private static let empty = LineTokens(spans: [])

    private static func tokens(_ blob: [LineTokens], at line: Int) -> LineTokens? {
        let index = line - 1
        guard index >= 0, index < blob.count else { return nil }
        return blob[index]
    }
}
