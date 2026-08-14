import AnySSHCore
import Testing

@testable import Highlighting

@Suite struct LanguageDetectorTests {
    private let detector = LanguageDetector()

    @Test(
        arguments: [
            ("src/App.swift", LanguageID.swift),
            ("web/index.TSX", .typescript),
            ("web/bundle.mjs", .javascript),
            ("tools/deploy.py", .python),
            ("cmd/main.go", .go),
            ("package.json", .json),
            ("ci/workflow.yml", .yaml),
            ("README.md", .markdown),
            ("Makefile", .plainText),
            ("archive.tar.gz", .plainText),
            (".gitignore", .plainText),
        ]
    )
    func extensionWins(path: String, expected: LanguageID) {
        #expect(detector.language(forPath: path) == expected)
    }

    @Test(
        arguments: [
            ("#!/usr/bin/env python3", LanguageID.python),
            ("#!/usr/bin/python", .python),
            ("#!/usr/bin/env node", .javascript),
            ("#!/usr/bin/env -S swift sh", .swift),
            ("#!/bin/bash", .plainText),
            ("not a shebang", .plainText),
        ]
    )
    func shebangIsTheFallback(firstLine: String, expected: LanguageID) {
        #expect(detector.language(forPath: "scripts/run", firstLine: firstLine) == expected)
    }

    @Test func aStatedExtensionBeatsAContradictingShebang() {
        let language = detector.language(forPath: "tools/deploy.py", firstLine: "#!/bin/sh")
        #expect(language == .python)
    }

    @Test func everyGrammarRoundTripsThroughLanguageID() {
        for grammar in TreeSitterGrammar.allCases {
            #expect(TreeSitterGrammar(grammar.id) == grammar)
        }
        #expect(TreeSitterGrammar(.plainText) == nil)
    }
}
