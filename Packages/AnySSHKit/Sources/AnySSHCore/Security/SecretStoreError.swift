import Foundation

public enum SecretStoreError: UserFacingError, Hashable {
    case writeDenied
    case readDenied
    case biometricCancelled
    case biometricUnavailable
    case migrationFailed

    public var stateID: String {
        state.stateID
    }

    public var state: SecretsErrorState {
        switch self {
        case .writeDenied: .keychainWriteDenied
        case .readDenied: .keychainReadDenied
        case .biometricCancelled: .biometricCancelled
        case .biometricUnavailable: .biometricUnavailable
        case .migrationFailed: .migrationFailed
        }
    }

    public init(write failure: KeychainFailure) {
        self = failure.status == errSecUserCanceled ? .biometricCancelled : .writeDenied
    }

    public init(read failure: KeychainFailure, gate: KeychainGate) {
        switch failure.status {
        case errSecUserCanceled:
            self = .biometricCancelled
        case errSecAuthFailed where gate != .none:
            self = .biometricUnavailable
        default:
            self = .readDenied
        }
    }
}
