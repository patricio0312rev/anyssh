import Foundation

public enum LinkScanner {
    private static let schemes = ["http", "https", "ssh", "file"]

    private static let urlCharacters: Set<Character> = [
        "-", ".", "_", "~", ":", "/", "?", "#", "[", "]", "@", "!",
        "$", "&", "'", "(", ")", "*", "+", ",", ";", "=", "%",
    ]

    private static let trailingPunctuation: Set<Character> = [".", ",", ")", "]", ">", "\"", "'"]

    public static func scan(rows: [LinkRow]) -> [LinkSpan] {
        let buffer = JoinedBuffer(rows: rows)
        var spans: [LinkSpan] = []
        var cursor = buffer.text.startIndex
        while cursor < buffer.text.endIndex {
            guard let prefixRange = schemePrefix(at: cursor, in: buffer.text) else {
                cursor = buffer.text.index(after: cursor)
                continue
            }
            let expanded = expand(from: prefixRange.lowerBound, in: buffer.text)
            guard let trimmed = trimTrailingPunctuation(expanded, in: buffer.text),
                let span = makeSpan(range: trimmed, buffer: buffer)
            else {
                cursor = buffer.text.index(after: prefixRange.lowerBound)
                continue
            }
            spans.append(span)
            cursor = trimmed.upperBound
        }
        return spans
    }

    private static func schemePrefix(at index: String.Index, in text: String) -> Range<String.Index>? {
        let rest = text[index...]
        for scheme in schemes {
            let prefix = scheme + "://"
            guard rest.prefix(prefix.count).lowercased() == prefix else { continue }
            guard index == text.startIndex || !isWordCharacter(text[text.index(before: index)]) else {
                return nil
            }
            return index..<text.index(index, offsetBy: prefix.count)
        }
        return nil
    }

    private static func expand(from start: String.Index, in text: String) -> Range<String.Index> {
        var end = start
        while end < text.endIndex, isURLCharacter(text[end]) {
            end = text.index(after: end)
        }
        return start..<end
    }

    private static func trimTrailingPunctuation(
        _ range: Range<String.Index>,
        in text: String
    ) -> Range<String.Index>? {
        var end = range.upperBound
        while end > range.lowerBound {
            let last = text.index(before: end)
            let character = text[last]
            guard trailingPunctuation.contains(character) else { break }
            if isClosingBracket(character), !isUnmatched(character, in: range.lowerBound..<end, text: text) {
                break
            }
            end = last
        }
        guard end > range.lowerBound else { return nil }
        return range.lowerBound..<end
    }

    private static func isClosingBracket(_ character: Character) -> Bool {
        character == ")" || character == "]"
    }

    private static func isUnmatched(
        _ closing: Character,
        in range: Range<String.Index>,
        text: String
    ) -> Bool {
        let opening: Character = closing == ")" ? "(" : "["
        var opens = 0
        var closes = 0
        for character in text[range] {
            if character == opening { opens += 1 }
            if character == closing { closes += 1 }
        }
        return closes > opens
    }

    private static func makeSpan(range: Range<String.Index>, buffer: JoinedBuffer) -> LinkSpan? {
        let candidate = String(buffer.text[range])
        guard let url = URL(string: candidate), let scheme = url.scheme?.lowercased() else {
            return nil
        }
        if scheme == "file" {
            guard !url.path().isEmpty else { return nil }
        } else {
            guard let host = url.host(), !host.isEmpty else { return nil }
        }
        let segments = buffer.segments(for: range)
        guard !segments.isEmpty else { return nil }
        return LinkSpan(segments: segments, url: url, text: candidate)
    }

    private static func isURLCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || urlCharacters.contains(character)
    }

    private static func isWordCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber
    }
}

private struct JoinedBuffer {
    let text: String
    private let rowStarts: [String.Index]

    init(rows: [LinkRow]) {
        var joined = ""
        var starts: [String.Index] = []
        for (index, row) in rows.enumerated() {
            if index > 0, !row.isWrapped {
                joined.append("\n")
            }
            starts.append(joined.endIndex)
            joined.append(contentsOf: row.text)
        }
        text = joined
        rowStarts = starts
    }

    func segments(for range: Range<String.Index>) -> [LinkSegment] {
        var result: [LinkSegment] = []
        var start = range.lowerBound
        for (row, rowStart) in rowStarts.enumerated() {
            let rowEnd = row + 1 < rowStarts.count ? rowStarts[row + 1] : text.endIndex
            guard start >= rowStart, start < rowEnd else { continue }
            let end = min(range.upperBound, rowEnd)
            let columnStart = text.distance(from: rowStart, to: start)
            let columnEnd = text.distance(from: rowStart, to: end)
            result.append(LinkSegment(row: row, columnRange: columnStart..<columnEnd))
            if end == range.upperBound { break }
            start = end
        }
        return result
    }
}
