public enum SecretsErrorState: String, ErrorStateMember {
    case keychainWriteDenied
    case keychainReadDenied
    case biometricCancelled
    case biometricUnavailable
    case migrationFailed
    case publicKeyOffered
    case keyFormatUnrecognised
    case keyTruncated
    case keyUnreadable
    case keyTooLarge
    case keyMissing

    public static let group = ErrorStateGroup.secrets

    public var copy: ErrorStateCopy {
        switch self {
        case .keychainWriteDenied:
            ErrorStateCopy(
                title: "Keychain write denied",
                body: "The system refused to save this secret. Unlock the device and try again.",
                recoveryLabel: "Try Again"
            )
        case .keychainReadDenied:
            ErrorStateCopy(
                title: "Keychain read denied",
                body: "The system refused to read this secret. Unlock the device and try again.",
                recoveryLabel: "Try Again"
            )
        case .biometricCancelled:
            ErrorStateCopy(
                title: "Authentication cancelled",
                body: "The key stays locked until you authenticate. Try again to unlock it.",
                recoveryLabel: "Try Again"
            )
        case .biometricUnavailable:
            ErrorStateCopy(
                title: "Biometrics unavailable",
                body: "Face ID or Touch ID changed on this device, so the stored key can no "
                    + "longer be read. Import the key again.",
                recoveryLabel: "Import Key Again"
            )
        case .migrationFailed:
            ErrorStateCopy(
                title: "Stored data not migrated",
                body: "Saved hosts and secrets are in a format this version does not read. "
                    + "Nothing was changed.",
                recoveryLabel: "Try Again"
            )
        case .publicKeyOffered:
            ErrorStateCopy(
                title: "That is a public key",
                body: "This is the public half, the part that belongs on the host. Import the "
                    + "private half, the file without the .pub extension.",
                recoveryLabel: "Paste"
            )
        case .keyFormatUnrecognised:
            ErrorStateCopy(
                title: "Key format not recognised",
                body: "A private key file opens with a BEGIN line naming OPENSSH or RSA. "
                    + "Nothing was read from what you pasted.",
                recoveryLabel: "Paste"
            )
        case .keyTruncated:
            ErrorStateCopy(
                title: "Key is incomplete",
                body: "This key stops before its end line, so part of it is missing. Copy the "
                    + "whole file and import it again.",
                recoveryLabel: "Paste"
            )
        case .keyUnreadable:
            ErrorStateCopy(
                title: "Key could not be read",
                body: "This key has an envelope but its body did not decode. Copy the whole "
                    + "file and import it again.",
                recoveryLabel: "Paste"
            )
        case .keyTooLarge:
            ErrorStateCopy(
                title: "File is too large for a key",
                body: "A private key is a few kilobytes. Nothing was read from this file. "
                    + "Choose the key itself rather than an archive that holds it.",
                recoveryLabel: "Choose File"
            )
        case .keyMissing:
            ErrorStateCopy(
                title: "Nothing to import",
                body: "No key text was found. Copy a private key and paste it, or choose the "
                    + "file it lives in.",
                recoveryLabel: "Paste"
            )
        }
    }

    public var owningPhase: Int {
        switch self {
        case .keychainWriteDenied, .keychainReadDenied, .biometricCancelled,
            .biometricUnavailable, .migrationFailed:
            15
        case .publicKeyOffered, .keyFormatUnrecognised, .keyTruncated, .keyUnreadable,
            .keyTooLarge, .keyMissing:
            16
        }
    }
}
