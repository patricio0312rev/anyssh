public enum KeyMaterialError: UserFacingError, Hashable {
    case nothingToImport
    case publicKeyOffered(PrivateKeyAlgorithm)
    case noEnvelope
    case unrecognisedEnvelope
    case truncated(PrivateKeyFormat)
    case unreadable(PrivateKeyFormat)
    case tooLarge

    public var stateID: String {
        switch self {
        case .nothingToImport: "secrets.keyMissing"
        case .publicKeyOffered: "secrets.publicKeyOffered"
        case .noEnvelope, .unrecognisedEnvelope: "secrets.keyFormatUnrecognised"
        case .truncated: "secrets.keyTruncated"
        case .unreadable: "secrets.keyUnreadable"
        case .tooLarge: "secrets.keyTooLarge"
        }
    }

    public var copy: ErrorStateCopy {
        switch self {
        case .nothingToImport:
            ErrorStateCopy(
                title: "Nothing to import",
                body: "No key text was found. Copy a private key and paste it, or choose the "
                    + "file it lives in.",
                recoveryLabel: "Paste"
            )
        case .publicKeyOffered(let algorithm):
            ErrorStateCopy(
                title: "That is a public key",
                body: "This is the \(Self.named(algorithm))public half, the part that belongs on "
                    + "the host. Import the private half, the file without the .pub extension.",
                recoveryLabel: "Paste"
            )
        case .noEnvelope, .unrecognisedEnvelope:
            ErrorStateCopy(
                title: "Key format not recognised",
                body: "\(Self.expected) Nothing was read from what you pasted.",
                recoveryLabel: "Paste"
            )
        case .truncated(let format):
            ErrorStateCopy(
                title: "Key is incomplete",
                body: "This \(format.label) key stops before its end line, so part of it is "
                    + "missing. Copy the whole file and import it again.",
                recoveryLabel: "Paste"
            )
        case .unreadable(let format):
            ErrorStateCopy(
                title: "Key could not be read",
                body: "This \(format.label) key has an envelope but its body did not decode. "
                    + "Copy the whole file and import it again.",
                recoveryLabel: "Paste"
            )
        case .tooLarge:
            ErrorStateCopy(
                title: "File is too large for a key",
                body: "A private key is a few kilobytes. Nothing was read from this file. "
                    + "Choose the key itself rather than an archive that holds it.",
                recoveryLabel: "Choose File"
            )
        }
    }

    public static let sizeLimit = 64 * 1024

    public var sawKeyMaterial: Bool {
        switch self {
        case .truncated, .unreadable: true
        case .nothingToImport, .publicKeyOffered, .noEnvelope, .unrecognisedEnvelope, .tooLarge:
            false
        }
    }

    private static func named(_ algorithm: PrivateKeyAlgorithm) -> String {
        algorithm == .unknown ? "" : "\(algorithm.label) "
    }

    static let expected =
        "A private key starts with "
        + PrivateKeyFormat.suggested.map(\.beginLine).joined(separator: " or ") + "."
}
