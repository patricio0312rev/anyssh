import AnySSHCore
import Foundation

public struct LogParser: Sendable {
    public init() {}

    public func parse(_ data: Data) throws -> [Commit] {
        data.split(separator: 1, omittingEmptySubsequences: true).compactMap { record in
            let fields = record.split(separator: 0, omittingEmptySubsequences: false).map {
                String(decoding: $0, as: UTF8.self)
            }
            guard fields.count >= 11, let date = ISO8601DateFormatter().date(from: fields[5]) else {
                return nil
            }
            return Commit(
                id: CommitID(rawValue: fields[0]),
                parents: fields[2].split(separator: " ").map { CommitID(rawValue: String($0)) },
                authorName: fields[3], authorEmail: fields[4], authoredAt: date,
                subject: fields[9], body: fields[10],
                references: fields[8].split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            )
        }
    }
}
