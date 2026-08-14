import AnySSHCore
import MarkdownView
import SwiftUI

public struct TreeSitterCodeBlockStyle: MarkdownCodeBlockStyle {
    let highlighter: any SyntaxHighlighter

    public init(highlighter: any SyntaxHighlighter) {
        self.highlighter = highlighter
    }

    public func makeBody(configuration: Configuration) -> some View {
        HighlightedCodeBlockView(
            code: configuration.code,
            language: configuration.language,
            highlighter: highlighter
        )
    }
}
