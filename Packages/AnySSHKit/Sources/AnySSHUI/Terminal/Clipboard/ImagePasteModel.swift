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
        guard let transport = connection as? any BlobUploadTransport else {
            outcome = .failed(.transfer(.files(.fetchFailed)))
            return nil
        }
        outcome = .uploading
        do {
            let path = try await ImagePasteUploader(connection: transport).upload(image)
            outcome = .uploaded(path: path)
            return path
        } catch {
            outcome = .failed(ImagePasteFailure(error))
            return nil
        }
    }
}
