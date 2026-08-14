import AnySSHCore

extension TreeSitterHighlighter {
    public func highlight(hunk: DiffHunk, language: LanguageID, sides: DiffSides) async
        -> HighlightedHunk
    {
        switch HighlightPolicy.tier(for: hunk, sides: sides, language: language) {
        case .rowTintOnly:
            return HighlightedHunk(tier: .rowTintOnly, rows: blankRows(for: hunk))
        case .hunkOnly:
            return HighlightedHunk(tier: .hunkOnly, rows: await hunkOnlyRows(hunk, language))
        case .wholeBlob:
            let needed = HighlightPolicy.neededSides(for: hunk)
            let old = needed.old ? await blobTokens(sides.old, language) : []
            let new = needed.new ? await blobTokens(sides.new, language) : []
            let rows = HunkSlicing.rows(for: hunk, old: old, new: new)
            return HighlightedHunk(tier: .wholeBlob, rows: rows)
        }
    }

    private func blobTokens(_ side: BlobSide?, _ language: LanguageID) async -> [LineTokens] {
        guard let side else { return [] }
        return await tokens(for: side.text, language: language, blobSha: side.sha)
    }

    private func hunkOnlyRows(_ hunk: DiffHunk, _ language: LanguageID) async -> [LineTokens] {
        let rows = await parse(HunkSlicing.text(of: hunk), language: language)
        guard rows.count != hunk.lines.count else { return rows }
        return (0..<hunk.lines.count).map { $0 < rows.count ? rows[$0] : LineTokens(spans: []) }
    }

    private func blankRows(for hunk: DiffHunk) -> [LineTokens] {
        Array(repeating: LineTokens(spans: []), count: hunk.lines.count)
    }
}
