import AnySSHCore
import FileTransfer
import Foundation
import Observation

@Observable
@MainActor
public final class FileImportModel {
    public enum Outcome: Equatable {
        case idle
        case uploading(name: String)
        case uploaded(path: String)
        case failed(ErrorState)
    }

    public private(set) var outcome: Outcome = .idle

    public init() {}

    private static func state(for error: any Error) -> ErrorState {
        if let state = error as? ErrorState { return state }
        if case UploadError.verificationFailed = error {
            return .files(.uploadVerificationFailed)
        }
        return .files(.fetchFailed)
    }

    public func upload(_ file: URL, over connection: any RemoteConnection) async -> String? {
        guard let ssh = connection as? any BlobUploadTransport else {
            outcome = .failed(.files(.fetchFailed))
            return nil
        }

        let scoped = file.startAccessingSecurityScopedResource()
        defer { if scoped { file.stopAccessingSecurityScopedResource() } }

        let name = file.lastPathComponent
        outcome = .uploading(name: name)
        do {
            let result = try await SSHBlobUploader(connection: ssh).upload(file: file, to: name)
            outcome = .uploaded(path: result.path)
            return result.path
        } catch {
            outcome = .failed(Self.state(for: error))
            return nil
        }
    }
}
