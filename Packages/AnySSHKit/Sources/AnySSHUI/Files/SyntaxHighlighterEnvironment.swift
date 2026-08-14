import AnySSHCore
import SwiftUI

struct PlainTextHighlighter: SyntaxHighlighter {
    func tokens(for blob: String, language: LanguageID) async -> [LineTokens] { [] }
}

private enum SyntaxHighlighterKey: EnvironmentKey {
    static let defaultValue: any SyntaxHighlighter = PlainTextHighlighter()
}

extension EnvironmentValues {
    public var syntaxHighlighter: any SyntaxHighlighter {
        get { self[SyntaxHighlighterKey.self] }
        set { self[SyntaxHighlighterKey.self] = newValue }
    }
}
