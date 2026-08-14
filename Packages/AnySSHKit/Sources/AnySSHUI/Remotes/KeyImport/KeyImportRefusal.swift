import AnySSHCore

public enum KeyImportRefusal: Equatable, Sendable {
    case key(KeyMaterialError)
    case secrets(SecretStoreError)

    public var stateID: String {
        switch self {
        case .key(let error): error.stateID
        case .secrets(let error): error.stateID
        }
    }

    public var copy: ErrorStateCopy {
        switch self {
        case .key(let error): error.copy
        case .secrets(let error): ErrorState.secrets(error.state).copy
        }
    }

    public var accessibilityIdentifier: String {
        "error.\(stateID)"
    }
}
