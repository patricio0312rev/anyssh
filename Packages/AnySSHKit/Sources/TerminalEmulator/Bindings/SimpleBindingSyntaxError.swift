public enum SimpleBindingSyntaxError: Error, Hashable, Sendable {
    case emptyText
    case leadingComma
    case trailingComma
    case newlineInText

    public var message: String {
        switch self {
        case .emptyText: "Empty text"
        case .leadingComma: "Starts with a comma"
        case .trailingComma: "Ends with a comma"
        case .newlineInText: "Line breaks are not allowed"
        }
    }
}
