import MarkdownView
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

public struct MarkdownDocumentView: MarkdownContentView {
    private let source: String
    private let configuration: MarkdownViewConfiguration

    public init(configuration: MarkdownViewConfiguration) {
        self.source = MarkdownSourceRewriter(filePath: configuration.filePath)
            .rewritingImages(in: configuration.source)
        self.configuration = configuration
    }

    public var body: some View {
        ScrollView {
            MarkdownView(source)
                .font(Self.blockQuoteFont, for: .blockQuote)
                .font(CodeFont.platformFont(size: CodeFont.defaultSize), for: .codeBlock)
                .markdownCodeBlockStyle(
                    TreeSitterCodeBlockStyle(highlighter: configuration.highlighter)
                )
                .markdownElementRenderer(
                    .image(
                        SSHMarkdownImageRenderer(loader: configuration.loader),
                        urlScheme: MarkdownImageURL.scheme
                    )
                )
                .padding(.horizontal, Theme.Space.screenMargin)
                .padding(.vertical, Theme.Space.step3)
                .textSelection(.enabled)
        }
        .background(Theme.surface.base)
        .accessibilityIdentifier(UIIdentifier.File.markdownViewer)
    }

    #if canImport(UIKit)
    private static let blockQuoteFont = UIFont.preferredFont(forTextStyle: .body)
    #else
    private static let blockQuoteFont = NSFont.preferredFont(forTextStyle: .body)
    #endif
}
