import Darwin
import Foundation

enum KnownHostsFile {
    static let name = "known_hosts"

    static func read(_ url: URL) -> [KnownHostsRecord] {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return text.split(separator: "\n").compactMap { KnownHostsRecord(line: String($0)) }
    }

    static func mutate(
        _ url: URL,
        _ change: ([KnownHostsRecord]) -> [KnownHostsRecord]
    ) throws -> [KnownHostsRecord] {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let lock = try Lock(url.appendingPathExtension("lock"))
        defer { lock.release() }

        let updated = change(read(url))
        let text = updated.compactMap(\.line).joined(separator: "\n")
        try Data((text.isEmpty ? "" : text + "\n").utf8).write(to: url, options: .atomic)
        return updated
    }

    private struct Lock {
        private let descriptor: Int32

        init(_ url: URL) throws {
            descriptor = open(url.path(percentEncoded: false), O_CREAT | O_RDWR, 0o600)
            guard descriptor >= 0 else {
                throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: url.path()])
            }
            while flock(descriptor, LOCK_EX) != 0 && errno == EINTR {}
        }

        func release() {
            flock(descriptor, LOCK_UN)
            close(descriptor)
        }
    }
}
