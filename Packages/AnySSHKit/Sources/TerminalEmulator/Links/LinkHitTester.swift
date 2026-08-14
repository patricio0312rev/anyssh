import Foundation

public enum LinkHitTester {
    public static func span(at row: Int, column: Int, in spans: [LinkSpan]) -> LinkSpan? {
        spans.first { $0.contains(row: row, column: column) }
    }
}
