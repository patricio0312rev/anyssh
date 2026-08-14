#if canImport(UIKit)
import AnySSHCore
import AnySSHMocks
import Fixtures
import Foundation
import Testing

@testable import AnySSHUI

@Suite @MainActor struct FilesJSONSnapshotTests {
    private let highlighter = MockSyntaxHighlighter()

    @Test func textModeRendersHighlighted() async throws {
        let text = try fixture("blobs/sample.json")
        let tokens = await highlighter.tokens(for: text, language: .json)
        ComponentSnapshot.assert(
            HighlightedCodeView(
                attributedText: HighlightedTextRenderer().attributed(blob: text, tokens: tokens)
            ),
            named: "jsonText",
            height: 520
        )
    }

    @Test func treeModeRendersVisibleRows() throws {
        let text = try fixture("blobs/sample.json")
        let root = try JSONTextParser.parse(text)
        var model = JSONTreeModel(root: root)
        guard let rootRow = model.rows.first else { return }
        model.expand(rootRow.id)
        let expandable = (1..<model.visibleRowCount).first { model.row(at: $0).isExpandable }
        if let expandable {
            model.expand(model.row(at: expandable).id)
        }
        ComponentSnapshot.assert(JSONTreeView(model: model), named: "jsonTree", height: 620)
    }

    private func fixture(_ path: String) throws -> String {
        try String(contentsOf: FixtureBundle.url(path), encoding: .utf8)
    }
}
#endif
