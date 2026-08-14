public enum BatchFramingError: Error, Hashable, Sendable, UserFacingError {
    case missingSection(label: String)
    case unterminatedSection(label: String)
    case desynchronised(label: String)
    case trailingBytes(label: String)
    case responseTooLarge(label: String, limit: Int)

    public var stateID: String {
        switch self {
        case .missingSection, .unterminatedSection, .desynchronised, .trailingBytes:
            ErrorState.command(.responseUnreadable).stateID
        case .responseTooLarge:
            ErrorState.command(.responseTooLarge).stateID
        }
    }

    public var label: String {
        switch self {
        case .missingSection(let label), .unterminatedSection(let label),
            .desynchronised(let label), .trailingBytes(let label),
            .responseTooLarge(let label, _):
            label
        }
    }
}
