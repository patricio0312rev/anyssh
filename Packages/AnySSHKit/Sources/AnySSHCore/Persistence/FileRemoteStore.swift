import Foundation

public actor FileRemoteStore: RemoteStore {
    public static let fileName = "remotes.json"

    private let fileURL: URL
    private var cached: RemoteList?

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public init(directory: URL) {
        self.init(fileURL: directory.appending(path: Self.fileName))
    }

    public static func applicationSupport() -> FileRemoteStore {
        FileRemoteStore(directory: URL.applicationSupportDirectory.appending(path: "AnySSH"))
    }

    public var location: URL {
        fileURL
    }

    public func remotes() async throws -> [Remote] {
        try list().remotes
    }

    public func save(_ remote: Remote) async throws {
        try mutate { $0.upsert(remote) }
    }

    public func delete(_ id: RemoteID) async throws {
        try mutate { $0.remove(id) }
    }

    public func reorder(to order: [RemoteID]) async throws {
        try mutate { $0.reorder(to: order) }
    }

    public func move(fromOffsets source: IndexSet, toOffset destination: Int) async throws {
        try mutate { $0.move(fromOffsets: source, toOffset: destination) }
    }

    private func list() throws -> RemoteList {
        if let cached { return cached }
        let loaded = try RemoteStoreDocument.read(from: fileURL)
        cached = loaded
        return loaded
    }

    private func mutate(_ change: (inout RemoteList) -> Void) throws {
        var updated = try list()
        change(&updated)
        try RemoteStoreDocument.write(updated, to: fileURL)
        cached = updated
    }
}
