import Foundation

@testable import TerminalEmulator

struct LinkScannerCase: Sendable, CustomStringConvertible {
    let name: String
    let rows: [LinkRow]
    let expected: [ExpectedSpan]

    init(_ name: String, rows: [LinkRow], expected: [ExpectedSpan]) {
        self.name = name
        self.rows = rows
        self.expected = expected
    }

    init(_ name: String, text: String, expected: [ExpectedSpan]) {
        self.name = name
        self.rows = [LinkRow(text: text, isWrapped: false)]
        self.expected = expected
    }

    var description: String { name }

    struct ExpectedSpan: Sendable, Equatable {
        let text: String
        let segments: [LinkSegment]

        init(_ text: String, segments: [LinkSegment]) {
            self.text = text
            self.segments = segments
        }

        init(_ text: String, row: Int = 0, columns: Range<Int>) {
            self.text = text
            self.segments = [LinkSegment(row: row, columnRange: columns)]
        }
    }
}
