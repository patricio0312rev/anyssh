import SwiftTreeSitter
import Testing

@testable import Highlighting

@Suite struct TreeSitterLoadTests {
    @Test func theRuntimeAcceptsABI15Grammars() {
        #expect(TreeSitterGrammar.runtimeABIVersion >= 15)
        #expect(TreeSitterGrammar.minimumSupportedABIVersion <= 14)
    }

    @Test func everyShippedGrammarLoadsUnderTheRuntimeABIRange() {
        for grammar in TreeSitterGrammar.allCases {
            let abi = grammar.language.ABIVersion
            #expect(abi >= TreeSitterGrammar.minimumSupportedABIVersion, "\(grammar) ABI \(abi)")
            #expect(abi <= TreeSitterGrammar.runtimeABIVersion, "\(grammar) ABI \(abi)")
        }
    }

    @Test(
        arguments: [
            (TreeSitterGrammar.swift, "struct Point { let x: Int }", "source_file"),
            (
                TreeSitterGrammar.typescript,
                "export const add = (a: number, b: number): number => a + b;",
                "program"
            ),
        ]
    )
    func parsesASnippetWithoutErrors(
        grammar: TreeSitterGrammar,
        source: String,
        rootType: String
    ) throws {
        let parser = Parser()
        try parser.setLanguage(grammar.language)

        let tree = try #require(parser.parse(source))
        let root = try #require(tree.rootNode)

        #expect(root.nodeType == rootType)
        #expect(root.hasError == false)
        #expect(root.childCount > 0)
    }
}
