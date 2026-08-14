import AnySSHCore
import Foundation

public actor FileHostKeyStore: HostKeyStore {
    public static let fileName = KnownHostsFile.name

    private let fileURL: URL
    private var cached: [KnownHostsRecord]?

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public init(directory: URL) {
        self.init(fileURL: directory.appending(path: Self.fileName))
    }

    public static func applicationSupport() -> FileHostKeyStore {
        FileHostKeyStore(directory: URL.applicationSupportDirectory.appending(path: "AnySSH"))
    }

    public var location: URL {
        fileURL
    }

    public func records() -> [KnownHostsRecord] {
        if let cached { return cached }
        let loaded = KnownHostsFile.read(fileURL)
        cached = loaded
        return loaded
    }

    public func knownKey(host: String, port: Int) async throws -> HostKey? {
        records().first { $0.addresses(host: host, port: port) }?.key
    }

    public func remember(_ key: HostKey, host: String, port: Int) async throws {
        let record = KnownHostsRecord(host: host, port: port, key: key)
        guard record.line != nil else { throw HostKeyStoreFailure.unwritableKey }
        try write { $0.filter { !$0.addresses(host: host, port: port) } + [record] }
    }

    public func forget(host: String, port: Int) async throws {
        try write { $0.filter { !$0.addresses(host: host, port: port) } }
    }

    private func write(_ change: @Sendable ([KnownHostsRecord]) -> [KnownHostsRecord]) throws {
        cached = try KnownHostsFile.mutate(fileURL, change)
    }
}

public enum HostKeyStoreFailure: UserFacingError, Equatable {
    case unwritableKey

    public var stateID: String {
        SecretsErrorState.migrationFailed.stateID
    }
}
