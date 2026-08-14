public enum FilesErrorState: String, ErrorStateMember {
    case blobTooLarge
    case lfsPointer
    case unsupportedVideo
    case svgParseFailed
    case svgTooLarge
    case imageDecodeFailed
    case jsonParseFailed
    case fetchFailed
    case uploadVerificationFailed
    case binaryFile

    public static let group = ErrorStateGroup.files

    public var copy: ErrorStateCopy {
        switch self {
        case .blobTooLarge:
            ErrorStateCopy(
                title: "File too large to open",
                body: "This file is over the limit for its type, so nothing was transferred. "
                    + "Open it anyway to load it in full.",
                recoveryLabel: "Open Anyway"
            )
        case .lfsPointer:
            ErrorStateCopy(
                title: "Stored with Git LFS",
                body: "The repository holds a pointer to this file rather than the file itself. "
                    + "Fetch it on the host to read it.",
                recoveryLabel: "View Pointer"
            )
        case .unsupportedVideo:
            ErrorStateCopy(
                title: "Unsupported video container",
                body: "iOS plays neither MKV nor WebM, whatever codec is inside. Convert the "
                    + "file on the host to watch it here.",
                recoveryLabel: "Dismiss"
            )
        case .svgParseFailed:
            ErrorStateCopy(
                title: "SVG could not be drawn",
                body: "This file did not parse as a drawable SVG. Its source is shown instead.",
                recoveryLabel: "View Source"
            )
        case .svgTooLarge:
            ErrorStateCopy(
                title: "SVG too large to draw",
                body: "This SVG is over 256 KB and was not parsed. Its source is shown instead.",
                recoveryLabel: "View Source"
            )
        case .imageDecodeFailed:
            ErrorStateCopy(
                title: "Image could not be decoded",
                body: "The file has an image extension but no readable image data. It may be "
                    + "truncated.",
                recoveryLabel: "Dismiss"
            )
        case .binaryFile:
            ErrorStateCopy(
                title: "Not a text file",
                body: "The start of this file is not text and no viewer here reads its type. "
                    + "Nothing beyond the first block was read.",
                recoveryLabel: "Dismiss"
            )
        case .jsonParseFailed:
            ErrorStateCopy(
                title: "Not valid JSON",
                body: "This file cannot be shown as a tree. Its text is shown instead.",
                recoveryLabel: "Show Text"
            )
        case .fetchFailed:
            ErrorStateCopy(
                title: "File could not be loaded",
                body: "The transfer stopped before the file arrived. Nothing on the host changed.",
                recoveryLabel: "Try Again"
            )
        case .uploadVerificationFailed:
            ErrorStateCopy(
                title: "Upload could not be verified",
                body: "The file on the host did not match the original, so it was removed.",
                recoveryLabel: "Try Again"
            )
        }
    }

    public var owningPhase: Int {
        switch self {
        case .blobTooLarge, .lfsPointer: 41
        case .imageDecodeFailed: 43
        case .unsupportedVideo, .svgParseFailed, .svgTooLarge: 44
        case .jsonParseFailed, .fetchFailed: 42
        case .uploadVerificationFailed: 59
        case .binaryFile: 60
        }
    }
}
