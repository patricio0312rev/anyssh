import AnySSHCore
import SwiftUI

struct HighlightedCodeBlockView: View {
    let code: String
    let language: String?
    let highlighter: any SyntaxHighlighter

    @State private var attributedCode: AttributedString?

    private static let renderer = HighlightedTextRenderer()
    private static let aliases = ["js": "javascript", "ts": "typescript"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let language, !language.isEmpty {
                Text(language)
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.Code.lineNumber)
                    .padding(.horizontal, Theme.Space.cardPadding)
                    .padding(.top, Theme.Space.step2)
            }
            ScrollView(.horizontal) {
                Text(renderedCode)
                    .textSelection(.enabled)
                    .padding(Theme.Space.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Code.canvas)
        .clipShape(.rect(cornerRadius: Theme.Space.cardRadius))
        .task(id: code) {
            var tokens = [LineTokens]()
            if let languageID {
                tokens = await highlighter.tokens(for: code, language: languageID)
            }
            attributedCode = Self.renderer.attributed(blob: code, tokens: tokens)
        }
    }

    private var renderedCode: AttributedString {
        attributedCode ?? Self.renderer.attributed(blob: code, tokens: [])
    }

    private var languageID: LanguageID? {
        guard let name = language?.lowercased() else { return nil }
        return LanguageID(rawValue: Self.aliases[name] ?? name)
    }
}
