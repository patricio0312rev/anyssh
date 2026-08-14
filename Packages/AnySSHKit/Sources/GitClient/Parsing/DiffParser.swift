import AnySSHCore
import Foundation

public struct DiffParser: Sendable {
    public init() {}

    public func parse(_ data: Data, file: ChangedFile) throws -> FileDiff {
        if data.starts(with: Data("diff --cc".utf8)) {
            throw GitParserError.state(.git(.combinedDiffUnsupported))
        }
        let lossy = String(data: data, encoding: .utf8) == nil
        let text = String(decoding: data, as: UTF8.self)
        var hunks = [DiffHunk]()
        var current: DiffHunkBuilder?
        var binary = false
        var truncated = false
        for raw in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(raw)
            if line.hasPrefix("Binary files ") || line == "GIT binary patch" {
                binary = true
                continue
            }
            if line.hasPrefix("diff --git ") || line.hasPrefix("diff --cc ") {
                if let current {
                    try validate(current)
                    hunks.append(current.build())
                }
                current = nil
                continue
            }
            if line.hasPrefix("@@ "), let header = parseHeader(line) {
                if let current {
                    try validate(current)
                    hunks.append(current.build())
                }
                current = DiffHunkBuilder(
                    oldStart: header.0, oldCount: header.1, newStart: header.2, newCount: header.3,
                    heading: header.4)
                continue
            }
            guard var builder = current else { continue }
            if line == "\\ No newline at end of file" {
                builder.markNoNewline()
                current = builder
                continue
            }
            guard let marker = line.first, marker == " " || marker == "+" || marker == "-" else { continue }
            let kind: DiffLineKind = marker == "+" ? .addition : marker == "-" ? .deletion : .context
            builder.append(DiffLine(kind: kind, text: String(line.dropFirst()), noNewlineAtEndOfFile: false))
            current = builder
            if builder.oldConsumed > builder.oldCount || builder.newConsumed > builder.newCount {
                truncated = true
            }
        }
        if let current {
            try validate(current)
            hunks.append(current.build())
        }
        if truncated { throw GitParserError.state(.git(.diffTruncated)) }
        return FileDiff(file: file, hunks: hunks, isBinary: binary, truncated: truncated, lossyDecode: lossy)
    }

    private func validate(_ builder: DiffHunkBuilder) throws {
        guard builder.oldConsumed == builder.oldCount, builder.newConsumed == builder.newCount else {
            throw GitParserError.state(.git(.diffTruncated))
        }
    }

    private func parseHeader(_ line: String) -> (Int, Int, Int, Int, String)? {
        guard line.hasPrefix("@@ "), let split = line.range(of: " @@") else { return nil }
        let start = line.index(line.startIndex, offsetBy: 3)
        guard start <= split.lowerBound else { return nil }
        let range = line[start..<split.lowerBound]
        let values = range.split(separator: " ").compactMap { part -> (Int, Int)? in
            let value = part.dropFirst()
            let pair = value.split(separator: ",")
            guard let first = pair.first, let startValue = Int(first) else { return nil }
            return (startValue, pair.count == 2 ? Int(pair[1]) ?? 1 : 1)
        }
        guard values.count == 2 else { return nil }
        let heading = String(line[split.upperBound...])
        return (values[0].0, values[0].1, values[1].0, values[1].1, heading)
    }
}

private struct DiffHunkBuilder: Sendable {
    let oldStart: Int
    let oldCount: Int
    let newStart: Int
    let newCount: Int
    let heading: String
    var lines = [DiffLine]()
    var oldConsumed = 0
    var newConsumed = 0
    var noNewline = false

    init(oldStart: Int, oldCount: Int, newStart: Int, newCount: Int, heading: String) {
        self.oldStart = oldStart
        self.oldCount = oldCount
        self.newStart = newStart
        self.newCount = newCount
        self.heading = heading
    }

    mutating func append(_ line: DiffLine) {
        lines.append(line)
        if line.kind != .addition { oldConsumed += 1 }
        if line.kind != .deletion { newConsumed += 1 }
    }

    mutating func markNoNewline() {
        noNewline = true
        if let index = lines.indices.last {
            lines[index] = DiffLine(
                kind: lines[index].kind, text: lines[index].text, noNewlineAtEndOfFile: true)
        }
    }

    func build() -> DiffHunk {
        DiffHunk(
            oldStart: oldStart, oldCount: oldCount, newStart: newStart, newCount: newCount, heading: heading,
            lines: lines)
    }
}
