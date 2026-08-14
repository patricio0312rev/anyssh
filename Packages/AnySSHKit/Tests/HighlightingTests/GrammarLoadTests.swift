import AnySSHCore
import SwiftTreeSitter
import Testing

@testable import Highlighting

@Suite struct GrammarLoadTests {
    private static let goldenTable: [TreeSitterGrammar: (fixture: String, positions: [GoldenPosition])] = [
        .swift: (
            "sample.swift",
            [
                GoldenPosition("struct keyword", 4, 0, .keyword),
                GoldenPosition("line comment", 9, 8, .comment),
                GoldenPosition("string literal origin", 14, 28, .string),
            ]
        ),
        .typescript: (
            "sample.ts",
            [
                GoldenPosition("interface keyword", 2, 7, .keyword),
                GoldenPosition("parameter type annotation", 7, 29, .type),
                GoldenPosition("string literal retrying", 8, 18, .string),
            ]
        ),
        .javascript: (
            "sample.js",
            [
                GoldenPosition("const keyword", 2, 0, .keyword),
                GoldenPosition("object property name", 2, 19, .variable),
                GoldenPosition("float literal", 5, 41, .number),
            ]
        ),
        .python: (
            "sample.py",
            [
                GoldenPosition("def keyword", 5, 0, .keyword),
                GoldenPosition("function name", 5, 4, .function),
                GoldenPosition("string literal retrying", 6, 12, .string),
            ]
        ),
        .go: (
            "sample.go",
            [
                GoldenPosition("struct type name", 6, 5, .type),
                GoldenPosition("function name", 11, 5, .function),
                GoldenPosition("string literal exhausted", 13, 27, .string),
            ]
        ),
        .json: (
            "sample.json",
            [
                GoldenPosition("mapping key", 2, 2, .variable),
                GoldenPosition("string value", 2, 10, .string),
                GoldenPosition("boolean literal", 4, 13, .number),
            ]
        ),
        .yaml: (
            "sample.yml",
            [
                GoldenPosition("comment", 1, 0, .comment),
                GoldenPosition("mapping key", 2, 0, .variable),
                GoldenPosition("quoted scalar", 10, 9, .string),
            ]
        ),
        .markdown: (
            "sample.md",
            [
                GoldenPosition("atx heading text", 1, 2, .function),
                GoldenPosition("fence info string", 8, 3, .attribute),
                GoldenPosition("fenced code content", 9, 0, .string),
            ]
        ),
    ]

    @Test func theGoldenTableCoversEveryShippedGrammar() {
        #expect(Set(Self.goldenTable.keys) == Set(TreeSitterGrammar.allCases))
        #expect(TreeSitterGrammar.allCases.count == 8)
    }

    @Test(arguments: TreeSitterGrammar.allCases)
    func everyGrammarCompilesItsHighlightQuery(grammar: TreeSitterGrammar) throws {
        let session = try #require(
            GrammarSession(grammar: grammar),
            "\(grammar) failed to build a parser or compile its query"
        )
        let captures = try #require(session.captures(in: "x"))
        #expect(captures.isEmpty || captures.allSatisfy { $0.lowerBound < $0.upperBound })
    }

    @Test func punctuationIsDeliberatelyNeverEmitted() async throws {
        let highlighter = TreeSitterHighlighter()
        for grammar in TreeSitterGrammar.allCases {
            guard let row = Self.goldenTable[grammar] else { continue }
            let tokens = await highlighter.tokens(
                for: try HighlightingFixtures.blob(row.fixture),
                language: grammar.id
            )
            let punctuation = tokens.flatMap(\.spans).filter { $0.scope == .punctuation }
            #expect(
                punctuation.isEmpty,
                "\(grammar) emitted punctuation, which renders identically to plain text"
            )
        }
    }

    @Test(arguments: TreeSitterGrammar.allCases)
    func scopesMatchTheGoldenTable(grammar: TreeSitterGrammar) async throws {
        let row = try #require(Self.goldenTable[grammar])
        let blob = try HighlightingFixtures.blob(row.fixture)
        let tokens = await TreeSitterHighlighter().tokens(for: blob, language: grammar.id)

        #expect(tokens.isEmpty == false, "\(grammar) produced no lines")
        for position in row.positions {
            let actual = HighlightingFixtures.scope(
                tokens,
                line: position.line,
                column: position.column
            )
            #expect(
                actual == position.scope,
                """
                \(grammar.rawValue) \(position.name) at \
                (\(position.line), \(position.column)): \
                expected \(position.scope.rawValue), got \(actual.rawValue)
                """
            )
        }
    }
}
