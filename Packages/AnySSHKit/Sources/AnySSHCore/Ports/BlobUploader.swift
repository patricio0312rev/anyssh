import Foundation

public struct BlobUploadResult: Sendable, Equatable {
    public let path: String
    public let byteCount: Int
    public let sha256: String

    public init(path: String, byteCount: Int, sha256: String) {
        self.path = path
        self.byteCount = byteCount
        self.sha256 = sha256
    }
}

public protocol BlobUploader: Sendable {
    func upload(file: URL, to path: String) async throws -> BlobUploadResult
}
