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
