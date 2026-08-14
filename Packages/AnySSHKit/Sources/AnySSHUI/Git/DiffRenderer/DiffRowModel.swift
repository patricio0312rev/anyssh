import AnySSHCore
import Foundation

public enum DiffRowKind: String, Sendable, Equatable {
    case hunk
    case context
    case addition
    case deletion
    case collapsed
    case placeholder
}

public struct DiffRow: Identifiable, Sendable, Equatable {
    public let id: String
    public let kind: DiffRowKind
    public let text: String
    public let oldLineNumber: Int?
    public let newLineNumber: Int?

    public init(
        id: String,
        kind: DiffRowKind,
        text: String,
        oldLineNumber: Int? = nil,
        newLineNumber: Int? = nil
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.oldLineNumber = oldLineNumber
        self.newLineNumber = newLineNumber
    }
}

public struct DiffRowModel: Sendable, Equatable {
    public let rows: [DiffRow]

    public init(diff: FileDiff, expandAll: Bool = false) {
        rows = DiffRowModel.makeRows(diff, expandAll: expandAll)
    }

    private static func makeRows(_ diff: FileDiff, expandAll: Bool) -> [DiffRow] {
        var output: [DiffRow] = []
        for (hunkIndex, hunk) in diff.hunks.enumerated() {
            output.append(DiffRow(id: "hunk-\(hunkIndex)", kind: .hunk, text: hunk.heading))
            output.append(contentsOf: lineRows(hunk, hunkIndex: hunkIndex, expandAll: expandAll))
            if !expandAll {
                output.append(
                    DiffRow(id: "collapsed-\(hunkIndex)", kind: .collapsed, text: "Expand context")
                )
            }
        }
        guard output.isEmpty else { return output }
        if diff.isBinary {
            return [DiffRow(id: "placeholder", kind: .placeholder, text: "Binary file")]
        }
        return [DiffRow(id: "placeholder", kind: .placeholder, text: "Mode-only change")]
    }

    private static func lineRows(_ hunk: DiffHunk, hunkIndex: Int, expandAll: Bool) -> [DiffRow] {
        var output: [DiffRow] = []
        var old = hunk.oldStart
        var new = hunk.newStart
        for (lineIndex, line) in (expandAll ? hunk.lines : collapsedLines(hunk.lines)).enumerated() {
            output.append(
                DiffRow(
                    id: "line-\(hunkIndex)-\(lineIndex)",
                    kind: line.kind.rowKind,
                    text: line.text,
                    oldLineNumber: line.kind == .addition ? nil : old,
                    newLineNumber: line.kind == .deletion ? nil : new
                )
            )
            if line.kind != .addition { old += 1 }
            if line.kind != .deletion { new += 1 }
        }
        return output
    }

    private static func collapsedLines(_ lines: [DiffLine]) -> [DiffLine] {
        guard lines.count > 3 else { return lines }
        return Array(lines.prefix(1)) + Array(lines.suffix(2))
    }
}

extension DiffLineKind {
    fileprivate var rowKind: DiffRowKind {
        switch self {
        case .context: .context
        case .addition: .addition
        case .deletion: .deletion
        }
    }
}
