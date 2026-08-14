import Foundation
import Testing

@testable import TerminalEmulator

@Suite struct LinkHitTesterTests {
    @Test
    func findsSpanOccupyingCell() {
        let rows = [
            LinkRow(text: "Docs live at https://example.com/releases/latest", isWrapped: false),
            LinkRow(text: "plain", isWrapped: false),
        ]
        let spans = LinkScanner.scan(rows: rows)
        #expect(spans.count == 1)

        let hit = LinkHitTester.span(at: 0, column: 20, in: spans)
        #expect(hit == spans[0])
        #expect(LinkHitTester.span(at: 0, column: 0, in: spans) == nil)
        #expect(LinkHitTester.span(at: 1, column: 0, in: spans) == nil)
    }

    @Test
    func wrappedSpanHitsEverySegment() {
        let original = "https://example.com/very/long/path/segment/continues-here"
        let rows = [
            LinkRow(
                text: String(repeating: " ", count: 40) + String(original.prefix(40)),
                isWrapped: false
            ),
            LinkRow(text: String(original.dropFirst(40)), isWrapped: true),
        ]
        let spans = LinkScanner.scan(rows: rows)
        #expect(spans.count == 1)

        #expect(LinkHitTester.span(at: 0, column: 45, in: spans) == spans[0])
        #expect(LinkHitTester.span(at: 1, column: 3, in: spans) == spans[0])
        #expect(LinkHitTester.span(at: 0, column: 10, in: spans) == nil)
    }
}
