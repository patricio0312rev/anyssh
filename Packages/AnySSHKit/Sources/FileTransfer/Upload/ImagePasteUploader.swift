import AnySSHCore
import Foundation
import os

public actor ImagePasteUploader {
    private static let log = Logger(subsystem: "com.patricio0312rev.anyssh", category: "image-paste")

    private let connection: any BlobUploadTransport
    private let limits: ImagePasteLimits
    private let stagingDirectory: URL
    private let now: @Sendable () -> Date
    private let token: @Sendable () -> String

    public init(
        connection: any BlobUploadTransport,
        limits: ImagePasteLimits = .standard,
        stagingDirectory: URL = FileManager.default.temporaryDirectory,
        now: @escaping @Sendable () -> Date = { Date() },
        token: @escaping @Sendable () -> String = { String(UUID().uuidString.prefix(8)).lowercased() }
    ) {
        self.connection = connection
        self.limits = limits
        self.stagingDirectory = stagingDirectory
        self.now = now
        self.token = token
    }

    public func upload(contentsOf data: Data) async throws -> String {
        try await upload(ImagePasteEncoder.image(from: data))
    }

    func upload(_ pasted: PastedImage) async throws -> String {
        let image = try ImagePasteEncoder.fit(pasted, limits: limits)
        let name = ImagePasteDestination.fileName(at: now(), token: token(), format: image.format)
        let staged = stagingDirectory.appending(path: UUID().uuidString + "-" + name)
        try image.data.write(to: staged, options: [.atomic, .completeFileProtection])
        defer { Self.discard(staged) }
        let uploader = SSHBlobUploader(
            connection: connection,
            rootProbe: ImagePasteDestination.prepareScript
        )
        return try await uploader.upload(file: staged, to: name).path
    }

    private static func discard(_ staged: URL) {
        do {
            try FileManager.default.removeItem(at: staged)
        } catch CocoaError.fileNoSuchFile {
            return
        } catch {
            log.error("staged image cleanup failed: \(String(describing: error), privacy: .public)")
        }
    }
}
