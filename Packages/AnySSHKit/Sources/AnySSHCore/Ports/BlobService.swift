public protocol BlobService: Sendable {
    func metadata(for refs: [BlobRef]) async throws -> [BlobMetadata]
    func fetch(_ ref: BlobRef, intent: BlobIntent) async throws -> FetchedBlob
}
