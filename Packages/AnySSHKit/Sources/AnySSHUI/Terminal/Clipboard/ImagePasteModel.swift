import AnySSHCore
import FileTransfer
import Foundation

@MainActor
public struct ImagePasteModel {
    public init() {}

    public func upload(
        contentsOf data: Data,
        over connection: any RemoteConnection
    ) async -> Result<String, ImagePasteFailure> {
        guard let transport = connection as? any BlobUploadTransport else {
            return .failure(.transfer(.files(.fetchFailed)))
        }
        do {
            return .success(try await ImagePasteUploader(connection: transport).upload(contentsOf: data))
        } catch {
            return .failure(ImagePasteFailure(error))
        }
    }

    public func uploadPhoto(
        over connection: any RemoteConnection,
        loading load: @escaping @Sendable () async throws -> Data?
    ) async -> Result<String, ImagePasteFailure> {
        let loaded: Data?
        do {
            loaded = try await load()
        } catch {
            return .failure(.photoUnavailable)
        }
        guard let loaded else { return .failure(.photoUnavailable) }
        return await upload(contentsOf: loaded, over: connection)
    }
}
