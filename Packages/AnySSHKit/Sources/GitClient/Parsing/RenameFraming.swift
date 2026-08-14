import AnySSHCore

public enum RenameFraming {
    public enum ParseError: Error, Equatable, Sendable {
        case notARenameRecord
        case malformedRecord
    }

    public static func statusV2(record: String) throws -> ChangedFile {
        let fields = record.split(separator: "\0", omittingEmptySubsequences: false)
        let header = fields[0].split(separator: " ")
        guard header.count >= 9 else { throw ParseError.malformedRecord }
        let score = header[8]
        guard score.first == "R", let similarity = Int(score.dropFirst()) else {
            throw ParseError.notARenameRecord
        }
        guard fields.count >= 3 else { throw ParseError.malformedRecord }
        let newPath = String(fields[1])
        let oldPath = String(fields[2])
        guard !newPath.isEmpty, !oldPath.isEmpty else { throw ParseError.malformedRecord }
        return ChangedFile(
            oldPath: oldPath,
            newPath: newPath,
            change: .renamed(similarity: similarity),
            isBinary: false
        )
    }

    public static func numstat(record: String) throws -> ChangedFile {
        let fields = record.split(separator: "\0", omittingEmptySubsequences: false)
        let counts = fields[0].split(separator: "\t", omittingEmptySubsequences: false)
        guard counts.count == 3 else { throw ParseError.malformedRecord }
        guard counts[2].isEmpty else { throw ParseError.notARenameRecord }
        guard isCount(counts[0]), isCount(counts[1]),
            (counts[0] == "-") == (counts[1] == "-")
        else { throw ParseError.malformedRecord }
        guard fields.count >= 3 else { throw ParseError.malformedRecord }
        let oldPath = String(fields[1])
        let newPath = String(fields[2])
        guard !oldPath.isEmpty, !newPath.isEmpty else { throw ParseError.malformedRecord }
        let isBinary = counts[0] == "-"
        return ChangedFile(
            oldPath: oldPath,
            newPath: newPath,
            change: .renamed(similarity: 0),
            isBinary: isBinary
        )
    }

    private static func isCount(_ value: Substring) -> Bool {
        value == "-" || (!value.isEmpty && value.allSatisfy(\.isNumber))
    }
}
