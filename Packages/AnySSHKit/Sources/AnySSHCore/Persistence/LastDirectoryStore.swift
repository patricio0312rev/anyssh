import Foundation

public struct LastDirectoryStore: Sendable {
    private struct Envelope: Codable {
        let schemaVersion: Int
        let directories: [String: String]
    }

    private static let schemaVersion = 1
    private static let fileName = "last-directories.json"

    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public static func applicationSupport() -> LastDirectoryStore {
        LastDirectoryStore(directory: URL.applicationSupportDirectory.appending(path: "AnySSH"))
    }

    public func path(for remote: RemoteID) -> String? {
        load()[remote.rawValue]
    }

    public func remember(_ path: String?, for remote: RemoteID) {
        var directories = load()
        let trimmed = path?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            directories[remote.rawValue] = trimmed
        } else {
            directories.removeValue(forKey: remote.rawValue)
        }
        save(directories)
    }

    private func load() -> [String: String] {
        guard let data = try? Data(contentsOf: fileURL),
            let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
            envelope.schemaVersion == Self.schemaVersion
        else {
            return [:]
        }
        return envelope.directories
    }

    private func save(_ directories: [String: String]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard
            let data = try? encoder.encode(
                Envelope(schemaVersion: Self.schemaVersion, directories: directories)
            )
        else {
            return
        }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }

    private var fileURL: URL {
        directory.appending(path: Self.fileName)
    }
}
