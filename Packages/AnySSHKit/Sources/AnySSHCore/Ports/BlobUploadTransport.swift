import Foundation

public protocol BlobUploadTransport: Sendable {
    func execute(_ command: String) async throws -> Data

    func uploadFile(_ file: URL, command: String) async throws
}
