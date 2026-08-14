import AnySSHCore

public enum SyntaxRole: String, CaseIterable, Sendable {
    case keyword
    case string
    case function
    case type
    case constant
    case property
    case comment
    case plain

    public var sRGBHex: String {
        switch self {
        case .keyword: "#ff6188"
        case .string: "#ffd866"
        case .function: "#a9dc76"
        case .type: "#78dce8"
        case .constant: "#ab9df2"
        case .property: "#fc9867"
        case .comment: "#727072"
        case .plain: "#fcfcfa"
        }
    }
}

public enum SyntaxPalette {
    public static func role(for scope: TokenScope) -> SyntaxRole {
        switch scope {
        case .keyword, .operator: .keyword
        case .string: .string
        case .function: .function
        case .type, .constant, .attribute: .type
        case .number: .constant
        case .variable: .property
        case .comment: .comment
        case .plain, .punctuation: .plain
        }
    }
}
