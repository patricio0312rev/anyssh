public struct LanguageID: Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension LanguageID {
    public static let swift = LanguageID(rawValue: "swift")
    public static let typescript = LanguageID(rawValue: "typescript")
    public static let javascript = LanguageID(rawValue: "javascript")
    public static let python = LanguageID(rawValue: "python")
    public static let go = LanguageID(rawValue: "go")
    public static let json = LanguageID(rawValue: "json")
    public static let yaml = LanguageID(rawValue: "yaml")
    public static let markdown = LanguageID(rawValue: "markdown")
}

public enum TokenScope: String, CaseIterable, Sendable {
    case keyword
    case string
    case number
    case comment
    case type
    case function
    case variable
    case constant
    case `operator`
    case punctuation
    case attribute
    case plain
}

public struct TokenSpan: Hashable, Sendable {
    public let range: Range<Int>
    public let scope: TokenScope

    public init(range: Range<Int>, scope: TokenScope) {
        self.range = range
        self.scope = scope
    }
}

public struct LineTokens: Hashable, Sendable {
    public let spans: [TokenSpan]

    public init(spans: [TokenSpan]) {
        self.spans = spans
    }
}
