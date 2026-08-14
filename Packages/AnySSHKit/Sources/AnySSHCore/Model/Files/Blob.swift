import Foundation

public struct BlobRef: Hashable, Sendable {
    public let repository: RepositoryRef
    public let objectID: String
    public let path: String

    public init(repository: RepositoryRef, objectID: String, path: String) {
        self.repository = repository
        self.objectID = objectID
        self.path = path
    }
}

public struct BlobMetadata: Hashable, Sendable {
    public let objectID: String
    public let type: String
    public let byteCount: Int

    public init(objectID: String, type: String, byteCount: Int) {
        self.objectID = objectID
        self.type = type
        self.byteCount = byteCount
    }
}

public enum BlobIntent: String, CaseIterable, Sendable {
    case diffSide
    case source
    case image
    case svg
    case video
}

public enum BlobContent: Sendable {
    case inMemory(Data)
    case file(URL)
}

public struct FetchedBlob: Sendable {
    public let ref: BlobRef
    public let content: BlobContent
    public let byteCount: Int
    public let truncated: Bool

    public init(ref: BlobRef, content: BlobContent, byteCount: Int, truncated: Bool) {
        self.ref = ref
        self.content = content
        self.byteCount = byteCount
        self.truncated = truncated
    }
}
