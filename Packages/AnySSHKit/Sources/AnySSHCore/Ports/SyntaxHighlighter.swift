public protocol SyntaxHighlighter: Sendable {
    func tokens(for blob: String, language: LanguageID) async -> [LineTokens]
}
