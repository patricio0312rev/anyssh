import AnySSHCore
import FileTransfer
import Foundation
import Observation

@Observable
@MainActor
public final class ImagePasteModel {
    public enum Outcome: Equatable {
        case idle
        case uploading
        case uploaded(path: String)
        case failed(ImagePasteFailure)
    }

    public private(set) var outcome: Outcome = .idle

    public init() {}

    public func upload(_ image: PastedImage, over connection: any RemoteConnection) async -> String? {
        guard let transport = transport(of: connection) else { return nil }
        outcome = .uploading
        return await finish { try await ImagePasteUploader(connection: transport).upload(image) }
    }

    public func uploadPhoto(
        over connection: any RemoteConnection,
        loading load: @escaping @Sendable () async throws -> Data?
    ) async -> String? {
        guard let transport = transport(of: connection) else { return nil }
        outcome = .uploading
        let data: Data
        do {
            guard let loaded = try await load() else {
                outcome = .failed(.photoUnavailable)
                return nil
            }
            data = loaded
        } catch {
            outcome = .failed(.photoUnavailable)
            return nil
        }
        return await finish {
            try await ImagePasteUploader(connection: transport).upload(contentsOf: data)
        }
    }

    private func transport(of connection: any RemoteConnection) -> (any BlobUploadTransport)? {
        guard let transport = connection as? any BlobUploadTransport else {
            outcome = .failed(.transfer(.files(.fetchFailed)))
            return nil
        }
        return transport
    }

    private func finish(_ operation: () async throws -> String) async -> String? {
        do {
            let path = try await operation()
            outcome = .uploaded(path: path)
            return path
        } catch {
            outcome = .failed(ImagePasteFailure(error))
            return nil
        }
    }
}
