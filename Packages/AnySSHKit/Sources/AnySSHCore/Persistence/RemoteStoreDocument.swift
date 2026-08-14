import Foundation

public enum RemoteStoreDocument {
    public static let schemaVersion = 2

    private struct Envelope: Codable {
        let schemaVersion: Int
        let remotes: [RemoteRecord]
    }

    private struct VersionProbe: Decodable {
        let schemaVersion: Int
    }

    public static func read(from url: URL) throws -> RemoteList {
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            return RemoteList()
        }
        return try decode(try data(at: url))
    }

    public static func write(_ list: RemoteList, to url: URL) throws {
        let envelope = Envelope(
            schemaVersion: schemaVersion,
            remotes: list.remotes.map(RemoteRecord.init)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let encoded = try encoder.encode(envelope)

        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try encoded.write(to: url, options: .atomic)
    }

    static func decode(_ encoded: Data) throws -> RemoteList {
        let decoder = JSONDecoder()
        guard let probe = try? decoder.decode(VersionProbe.self, from: encoded) else {
            throw RemoteStoreError.unreadable("no schema version")
        }
        guard probe.schemaVersion >= 1, probe.schemaVersion <= schemaVersion else {
            throw RemoteStoreError.unsupportedSchemaVersion(probe.schemaVersion)
        }
        do {
            return RemoteList(try decoder.decode(Envelope.self, from: encoded).remotes.map(\.remote))
        } catch {
            throw RemoteStoreError.unreadable(String(describing: error))
        }
    }

    private static func data(at url: URL) throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            throw RemoteStoreError.unreadable(String(describing: error))
        }
    }
}
