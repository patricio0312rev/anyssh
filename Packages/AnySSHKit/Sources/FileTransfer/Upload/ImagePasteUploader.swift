import AnySSHCore
import Foundation

public actor ImagePasteUploader {
    private let connection: any BlobUploadTransport
    private let limits: ImagePasteLimits
    private let stagingDirectory: URL
    private let now: @Sendable () -> Date

    public init(
        connection: any BlobUploadTransport,
        limits: ImagePasteLimits = .standard,
        stagingDirectory: URL = FileManager.default.temporaryDirectory,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.connection = connection
        self.limits = limits
        self.stagingDirectory = stagingDirectory
        self.now = now
    }

    public func upload(contentsOf data: Data) async throws -> String {
        try await upload(ImagePasteEncoder.image(from: data))
    }

    public func upload(_ pasted: PastedImage) async throws -> String {
        let image = try ImagePasteEncoder.fit(pasted, limits: limits)
        let name = ImagePasteDestination.fileName(at: now(), format: image.format)
        let staged = stagingDirectory.appending(path: UUID().uuidString + "-" + name)
        try image.data.write(to: staged, options: [.atomic, .completeFileProtection])
        defer { try? FileManager.default.removeItem(at: staged) }
        let uploader = SSHBlobUploader(
            connection: connection,
            rootProbe: ImagePasteDestination.prepareScript
        )
        return try await uploader.upload(file: staged, to: name).path
    }
}
