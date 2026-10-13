import AnySSHCore
import FileTransfer

public enum ImagePasteFailure: Error, Equatable, Sendable {
    case unreadable
    case tooLarge
    case photoUnavailable
    case transfer(ErrorState)

    init(_ error: any Error) {
        if case ImagePasteEncoder.Failure.unreadable = error {
            self = .unreadable
        } else if case ImagePasteEncoder.Failure.tooLarge = error {
            self = .tooLarge
        } else if case UploadError.verificationFailed = error {
            self = .transfer(.files(.uploadVerificationFailed))
        } else if let state = error as? ErrorState {
            self = .transfer(state)
        } else {
            self = .transfer(.files(.fetchFailed))
        }
    }
}
