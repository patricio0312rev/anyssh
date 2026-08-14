import Foundation

public struct LinkSegment: Equatable, Sendable {
    public let row: Int
    public let columnRange: Range<Int>

    public init(row: Int, columnRange: Range<Int>) {
        self.row = row
        self.columnRange = columnRange
    }
}

public struct LinkSpan: Equatable, Sendable {
    public let segments: [LinkSegment]
    public let url: URL
    public let text: String

    public init(segments: [LinkSegment], url: URL, text: String) {
        self.segments = segments
        self.url = url
        self.text = text
    }

    public func contains(row: Int, column: Int) -> Bool {
        segments.contains { $0.row == row && $0.columnRange.contains(column) }
    }
}
