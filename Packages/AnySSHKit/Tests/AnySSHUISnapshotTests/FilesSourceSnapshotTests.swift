#if canImport(UIKit)
import AnySSHCore
import AnySSHMocks
import Fixtures
import Foundation
import SwiftUI
import Testing

@testable import AnySSHUI

@Suite @MainActor struct FilesSourceSnapshotTests {
    private let highlighter = MockSyntaxHighlighter()

    @Test func swiftBlobRendersHighlighted() async throws {
        let text = try fixture("blobs/sample.swift")
        let tokens = await highlighter.tokens(for: text, language: .swift)
        ComponentSnapshot.assert(highlighted(text, tokens), named: "sourceSwift", height: 700)
    }

    @Test func typescriptBlobRendersHighlighted() async throws {
        let text = try fixture("blobs/sample.ts")
        let tokens = await highlighter.tokens(for: text, language: .typescript)
        ComponentSnapshot.assert(highlighted(text, tokens), named: "sourceTypeScript", height: 700)
    }

    @Test func codeTextViewNumbersEveryLine() async throws {
        let text = try fixture("blobs/sample.swift")
        let tokens = await highlighter.tokens(for: text, language: .swift)
        let lines = text.components(separatedBy: "\n")
        ComponentSnapshot.assert(
            CodeTextView(lines: lines, tokens: tokens, wraps: true),
            named: "codeTextWrapped",
            height: 700
        )
    }

    private func highlighted(_ text: String, _ tokens: [LineTokens]) -> some View {
        HighlightedCodeView(
            attributedText: HighlightedTextRenderer().attributed(blob: text, tokens: tokens)
        )
    }

    private func fixture(_ path: String) throws -> String {
        try String(contentsOf: FixtureBundle.url(path), encoding: .utf8)
    }
}
#endif
