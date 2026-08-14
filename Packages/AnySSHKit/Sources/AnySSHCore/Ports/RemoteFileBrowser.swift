public protocol RemoteFileBrowser: Sendable {
    func list(path: String) async throws -> DirectoryListing
    func read(path: String) async throws -> FileContentCommand.Content
}
