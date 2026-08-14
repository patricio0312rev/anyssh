import Foundation
import Testing

@testable import TerminalEmulator

@Suite struct LinkScannerTests {
    @Test(arguments: LinkScannerTable.cases)
    func scansExactRanges(testCase: LinkScannerCase) {
        let spans = LinkScanner.scan(rows: testCase.rows)
        let found = spans.map {
            LinkScannerCase.ExpectedSpan($0.text, segments: $0.segments)
        }
        #expect(found == testCase.expected, "case \(testCase.name)")
    }

    @Test
    func wrappedURLReconstructsUnwrappedOriginalByteForByte() {
        let original = "https://example.com/very/long/path/segment/continues-here"
        let head = String(repeating: " ", count: 40) + String(original.prefix(40))
        let tail = String(original.dropFirst(40))
        let rows = [
            LinkRow(text: head, isWrapped: false),
            LinkRow(text: tail, isWrapped: true),
        ]

        let spans = LinkScanner.scan(rows: rows)
        #expect(spans.count == 1)
        #expect(spans[0].text == original)
        #expect(Array(spans[0].text.utf8) == Array(original.utf8))
        #expect(spans[0].segments.count == 2)
    }

    @Test
    func threeRowWrapIsOneSpan() {
        let original = "https://example.com/part-two/more-path/and-still-going"
        let rows = [
            LinkRow(text: String(repeating: " ", count: 60) + String(original.prefix(13)), isWrapped: false),
            LinkRow(text: String(original.dropFirst(13).prefix(34)), isWrapped: true),
            LinkRow(text: String(original.dropFirst(47)), isWrapped: true),
        ]

        let spans = LinkScanner.scan(rows: rows)
        #expect(spans.count == 1)
        #expect(spans[0].text == original)
        #expect(spans[0].segments.count == 3)
    }

    @Test
    func wrapFlagNotRowLengthDecidesStitching() {
        let rows = [
            LinkRow(text: String(repeating: "a", count: 80), isWrapped: false),
            LinkRow(text: "https://example.com", isWrapped: false),
        ]

        let spans = LinkScanner.scan(rows: rows)
        #expect(spans.map(\.text) == ["https://example.com"])
        #expect(spans[0].segments == [LinkSegment(row: 1, columnRange: 0..<19)])
    }

    @Test
    func tableHasAtLeastThirtyRows() {
        #expect(LinkScannerTable.cases.count >= 30)
    }
}
