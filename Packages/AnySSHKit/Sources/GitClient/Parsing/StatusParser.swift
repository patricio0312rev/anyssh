import AnySSHCore
import Foundation

public struct StatusParser: Sendable {
    public init() {}

    public func parse(_ data: Data) throws -> RepositoryStatus {
        let records = data.split(separator: 0, omittingEmptySubsequences: true)
        var head: HeadState = .detached(CommitID(rawValue: ""))
        var upstream: UpstreamTracking?
        var staged = [ChangedFile]()
        var unstaged = [ChangedFile]()
        var untracked = [String]()
        var unmerged = [ChangedFile]()
        var index = 0
        while index < records.count {
            let record = records[index]
            let text = String(decoding: record, as: UTF8.self)
            if text.hasPrefix("# branch.oid ") {
                head = parseOID(String(text.dropFirst(13)), current: head)
                index += 1
                continue
            }
            if text.hasPrefix("# branch.head ") {
                head = parseHead(String(text.dropFirst(14)), current: head)
                index += 1
                continue
            }
            if let name = text.dropPrefix("# branch.upstream ") {
                upstream = UpstreamTracking(name: name, ahead: 0, behind: 0)
                index += 1
                continue
            }
            if let counts = text.dropPrefix("# branch.ab ") {
                upstream = parseAheadBehind(counts, upstream: upstream)
                index += 1
                continue
            }
            guard let kind = text.first else {
                index += 1
                continue
            }
            if kind == "?" {
                untracked.append(String(text.dropFirst(2)))
                index += 1
                continue
            }
            if kind == "!" {
                index += 1
                continue
            }
            guard kind == "1" || kind == "2" || kind == "u" else {
                index += 1
                continue
            }
            let fields = text.split(separator: " ", omittingEmptySubsequences: true)
            let recordData: Data
            if kind == "2" {
                guard index + 2 < records.count else { throw GitParserError.malformed("rename") }
                recordData =
                    Data(record) + Data([0]) + Data(records[index + 1]) + Data([0]) + Data(records[index + 2])
                index += 3
            } else {
                recordData = Data(record)
                index += 1
            }
            let file = try parseFile(fields, record: recordData, kind: kind)
            if kind == "u" {
                unmerged.append(file)
                continue
            }
            guard fields.count >= 2 else { throw GitParserError.malformed("status") }
            let xy = fields[1]
            if xy.first != "." { staged.append(file) }
            if xy.last != "." { unstaged.append(file) }
        }
        return RepositoryStatus(
            head: head, upstream: upstream, staged: staged, unstaged: unstaged, untracked: untracked,
            unmerged: unmerged)
    }

    private func parseOID(_ value: String, current: HeadState) -> HeadState {
        value == "(initial)" ? .unborn("HEAD") : current
    }

    private func parseHead(_ value: String, current: HeadState) -> HeadState {
        if value == "(detached)" { return current }
        if value == "(unknown)" { return current }
        if case .unborn = current { return .unborn(value) }
        return .branch(value)
    }

    private func parseAheadBehind(_ value: String, upstream: UpstreamTracking?) -> UpstreamTracking? {
        let values = value.split(separator: " ").compactMap { Int($0) }
        guard values.count == 2, let upstream else { return upstream }
        return UpstreamTracking(name: upstream.name, ahead: abs(values[0]), behind: abs(values[1]))
    }

    private func parseFile(_ fields: [Substring], record: Data, kind: Character) throws -> ChangedFile {
        if kind == "2" {
            let paths = record.split(separator: 0, omittingEmptySubsequences: false).dropFirst(1)
            guard let new = paths.first, let old = paths.dropFirst().first else {
                throw GitParserError.malformed("rename")
            }
            guard let scoreField = fields.last, scoreField.first == "R",
                let score = Int(scoreField.dropFirst())
            else { throw GitParserError.malformed("rename") }
            return ChangedFile(
                oldPath: String(decoding: old, as: UTF8.self), newPath: String(decoding: new, as: UTF8.self),
                change: .renamed(similarity: score), isBinary: false)
        }
        guard let path = fields.last else { throw GitParserError.malformed("path") }
        let change: FileChange
        switch kind {
        case "u": change = .unmerged
        default:
            guard fields.count >= 2 else { throw GitParserError.malformed("status") }
            change = fields[1].first == "A" ? .added : fields[1].first == "D" ? .deleted : .modified
        }
        let modes = fields.dropFirst(2).prefix(3)
        let modeChanged = modes.count == 3 && Set(modes).count > 1
        return ChangedFile(
            oldPath: change.isRename ? String(path) : nil, newPath: String(path),
            change: modeChanged ? .typeChanged : change, isBinary: false)
    }
}

extension String {
    fileprivate func dropPrefix(_ prefix: String) -> String? {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : nil
    }
}
