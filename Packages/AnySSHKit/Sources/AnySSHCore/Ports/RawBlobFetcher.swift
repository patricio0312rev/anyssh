import Foundation

public protocol RawBlobChannel: Sendable {
    func receive() async throws -> Data?
    func close() async
}

public protocol RawBlobFetcher: Sendable {
    func openBlobChannel(repository: RepositoryRef, objectID: String) async throws -> any RawBlobChannel
}
