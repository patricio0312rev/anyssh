import Foundation
import Markdown

struct MarkdownSourceRewriter {
    let filePath: String

    func rewritingImages(in text: String) -> String {
        var walker = ImageCollector()
        walker.visit(Document(parsing: text))
        let replacements = walker.images.compactMap { replacement(for: $0, in: text) }
        guard !replacements.isEmpty else { return text }
        var result = text
        for (range, rewritten) in replacements.reversed() {
            result.replaceSubrange(range, with: rewritten)
        }
        return result
    }

    private func replacement(for image: Markdown.Image, in text: String)
        -> (Range<String.Index>, String)?
    {
        guard let nodeRange = image.range, image.source != nil else { return nil }
        guard let bounds = bounds(for: nodeRange, in: text) else { return nil }
        guard let opener = imageOpener(in: text, within: bounds) else { return nil }
        guard let destinationRange = destinationRange(in: text, after: opener) else { return nil }
        let destinationText = String(text[destinationRange])
        let rewritten = MarkdownURLRewriter.rewrittenURL(
            for: destinationText,
            relativeTo: filePath
        )
        guard rewritten != destinationText else { return nil }
        return (destinationRange, rewritten)
    }

    private func imageOpener(in text: String, within bounds: Range<String.Index>) -> String.Index? {
        guard let found = text[bounds].firstRange(of: "](") else { return nil }
        return text.index(after: found.lowerBound)
    }

    private func destinationRange(in text: String, after opener: String.Index)
        -> Range<String.Index>?
    {
        var index = text.index(after: opener)
        guard index < text.endIndex else { return nil }
        if text[index] == "<" {
            let contentStart = text.index(after: index)
            guard let close = text[contentStart...].firstIndex(of: ">") else { return nil }
            return contentStart..<close
        }
        var depth = 0
        while index < text.endIndex {
            let character = text[index]
            if character == "\\" {
                index = text.index(index, offsetBy: 2, limitedBy: text.endIndex) ?? text.endIndex
                continue
            }
            if character == "(" {
                depth += 1
            } else if character == ")" {
                if depth == 0 { break }
                depth -= 1
            } else if character == "\"" || character == "'" || character == " "
                || character == "\t" || character == "\n"
            {
                break
            }
            index = text.index(after: index)
        }
        let start = text.index(after: opener)
        guard start < index else { return nil }
        return start..<index
    }

    private func bounds(for range: Range<SourceLocation>, in text: String) -> Range<String.Index>? {
        guard let lower = index(for: range.lowerBound, in: text),
            let upper = index(for: range.upperBound, in: text)
        else { return nil }
        return lower..<upper
    }

    private func index(for location: SourceLocation, in text: String) -> String.Index? {
        guard location.line > 0, location.column > 0 else { return nil }
        var currentLine = 1
        var lineStart = text.startIndex
        while currentLine < location.line {
            guard let newline = text[lineStart...].firstIndex(of: "\n") else { return nil }
            lineStart = text.index(after: newline)
            currentLine += 1
        }
        let lineEnd = text[lineStart...].firstIndex(of: "\n") ?? text.endIndex
        let line = text[lineStart..<lineEnd]
        let byteOffset = location.column - 1
        guard byteOffset <= line.utf8.count else { return lineEnd }
        return line.utf8.index(line.utf8.startIndex, offsetBy: byteOffset)
    }

    private struct ImageCollector: MarkupWalker {
        var images: [Markdown.Image] = []

        mutating func visitImage(_ image: Markdown.Image) {
            images.append(image)
        }
    }
}
