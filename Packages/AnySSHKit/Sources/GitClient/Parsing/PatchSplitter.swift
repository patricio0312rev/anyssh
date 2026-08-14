import AnySSHCore
import Foundation

public enum PatchSplitter {
    public struct Segment: Sendable {
        public let file: ChangedFile
        public let patch: Data
    }

    public static func split(_ data: Data) -> [Segment] {
        let text = String(decoding: data, as: UTF8.self)
        var segments = [Segment]()
        var lines = [Substring]()
        var header: (old: String?, new: String?)?

        func flush() {
            guard let header, let file = changedFile(from: header) else {
                lines = []
                return
            }
            segments.append(
                Segment(file: counted(file, in: lines), patch: Data(lines.joined(separator: "\n").utf8))
            )
            lines = []
        }

        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix("diff --git ") || line.hasPrefix("diff --cc ") {
                flush()
                header = (nil, nil)
            }
            if line.hasPrefix("--- ") { header?.old = path(from: line, prefix: "a/") }
            if line.hasPrefix("+++ ") { header?.new = path(from: line, prefix: "b/") }
            lines.append(line)
        }
        flush()
        return segments
    }

    private static func counted(_ file: ChangedFile, in lines: [Substring]) -> ChangedFile {
        var additions = 0
        var deletions = 0
        var inHunk = false
        for line in lines {
            if line.hasPrefix("@@ ") {
                inHunk = true
                continue
            }
            guard inHunk, let marker = line.first else { continue }
            if marker == "+" { additions += 1 }
            if marker == "-" { deletions += 1 }
        }
        return ChangedFile(
            oldPath: file.oldPath,
            newPath: file.newPath,
            change: file.change,
            isBinary: file.isBinary,
            additions: additions,
            deletions: deletions
        )
    }

    private static func changedFile(from header: (old: String?, new: String?)) -> ChangedFile? {
        let old = header.old == "/dev/null" ? nil : header.old
        let new = header.new == "/dev/null" ? nil : header.new
        guard old != nil || new != nil else { return nil }
        let change: FileChange =
            old == nil ? .added : new == nil ? .deleted : old == new ? .modified : .renamed(similarity: 100)
        return ChangedFile(oldPath: old, newPath: new, change: change, isBinary: false)
    }

    private static func path(from line: Substring, prefix: String) -> String {
        let value = String(line.dropFirst(4))
        return value.hasPrefix(prefix) ? String(value.dropFirst(prefix.count)) : value
    }
}
