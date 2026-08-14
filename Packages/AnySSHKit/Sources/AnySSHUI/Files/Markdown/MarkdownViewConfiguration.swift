import AnySSHCore
import Foundation
import SwiftUI

public protocol MarkdownImageLoader: Sendable {
    func loadImage(repositoryPath: String) async throws -> Data
}

public struct MarkdownViewConfiguration {
    public let source: String
    public let filePath: String
    public let loader: any MarkdownImageLoader
    public let highlighter: any SyntaxHighlighter

    public init(
        source: String,
        filePath: String,
        loader: any MarkdownImageLoader,
        highlighter: any SyntaxHighlighter
    ) {
        self.source = source
        self.filePath = filePath
        self.loader = loader
        self.highlighter = highlighter
    }
}

public protocol MarkdownContentView: View {
    init(configuration: MarkdownViewConfiguration)
}
