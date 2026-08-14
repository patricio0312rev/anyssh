import Foundation

public struct SessionRestoreStore: Sendable {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public init(directory: URL) {
        self.init(fileURL: directory.appending(path: SessionRestorePolicy.fileName))
    }

    public var location: URL {
        fileURL
    }

    public static func applicationSupport() -> SessionRestoreStore {
        SessionRestoreStore(
            directory: URL.applicationSupportDirectory.appending(path: "AnySSH")
        )
    }

    public func load() throws -> SessionRestoreSnapshot? {
        try SessionRestoreDocument.read(from: fileURL)
    }

    public func save(_ snapshot: SessionRestoreSnapshot) throws {
        try SessionRestoreDocument.write(snapshot, to: fileURL)
    }

    public func clear() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            return
        }
        try FileManager.default.removeItem(at: fileURL)
    }
}
