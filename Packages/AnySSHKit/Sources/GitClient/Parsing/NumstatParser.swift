import AnySSHCore
import Foundation

public struct NumstatParser: Sendable {
    public init() {}

    public func parse(_ data: Data) throws -> [ChangedFile] {
        let records = data.split(separator: 0, omittingEmptySubsequences: true)
        var files = [ChangedFile]()
        var index = 0
        while index < records.count {
            let record = String(decoding: records[index], as: UTF8.self)
            let fields = record.split(separator: "\t", omittingEmptySubsequences: false)
            guard fields.count == 3 else { throw GitParserError.malformed("numstat") }
            if fields[2].isEmpty {
                guard index + 2 < records.count else { throw GitParserError.malformed("rename") }
                let rename =
                    record + "\0" + String(decoding: records[index + 1], as: UTF8.self)
                    + "\0" + String(decoding: records[index + 2], as: UTF8.self)
                files.append(try RenameFraming.numstat(record: rename))
                index += 3
                continue
            }
            guard isCount(fields[0]), isCount(fields[1]) else { throw GitParserError.malformed("numstat") }
            let path = String(fields[2])
            let change: FileChange =
                fields[0] == "0" && fields[1] != "0"
                ? .deleted : fields[0] != "0" && fields[1] == "0" ? .added : .modified
            files.append(
                ChangedFile(
                    oldPath: change == .added ? nil : path,
                    newPath: change == .deleted ? nil : path,
                    change: change,
                    isBinary: fields[0] == "-",
                    additions: Int(fields[0]) ?? 0,
                    deletions: Int(fields[1]) ?? 0
                )
            )
            index += 1
        }
        return files
    }

    private func isCount(_ value: Substring) -> Bool {
        value == "-" || (!value.isEmpty && value.allSatisfy(\.isNumber))
    }
}
