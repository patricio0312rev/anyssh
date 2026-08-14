import AnySSHCore
import Fixtures
import Foundation

@testable import Highlighting

enum HighlightingFixtures {
    static func blob(_ name: String) throws -> String {
        try String(contentsOf: FixtureBundle.url("blobs/\(name)"), encoding: .utf8)
    }

    static func scope(_ tokens: [LineTokens], line: Int, column: Int) -> TokenScope {
        guard line >= 1, line <= tokens.count else { return .plain }
        for span in tokens[line - 1].spans where span.range.contains(column) { return span.scope }
        return .plain
    }
}

struct GoldenPosition: Sendable {
    let name: String
    let line: Int
    let column: Int
    let scope: TokenScope

    init(_ name: String, _ line: Int, _ column: Int, _ scope: TokenScope) {
        self.name = name
        self.line = line
        self.column = column
        self.scope = scope
    }
}
