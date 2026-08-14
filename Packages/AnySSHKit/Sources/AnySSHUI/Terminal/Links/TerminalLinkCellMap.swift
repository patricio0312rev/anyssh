import CoreGraphics
import TerminalEmulator

public struct TerminalLinkCellMap: Equatable, Sendable {
    public let columns: Int
    public let rows: Int
    public let bounds: CGRect

    public init(columns: Int, rows: Int, bounds: CGRect) {
        self.columns = max(1, columns)
        self.rows = max(1, rows)
        self.bounds = bounds
    }

    public var cellSize: CGSize {
        CGSize(
            width: bounds.width / CGFloat(columns),
            height: bounds.height / CGFloat(rows)
        )
    }

    public func cell(at point: CGPoint) -> (row: Int, column: Int)? {
        guard bounds.contains(point) else { return nil }
        let size = cellSize
        guard size.width > 0, size.height > 0 else { return nil }
        let column = Int((point.x - bounds.minX) / size.width)
        let row = Int((point.y - bounds.minY) / size.height)
        guard row >= 0, row < rows, column >= 0, column < columns else { return nil }
        return (row, column)
    }

    public func frame(row: Int, column: Int) -> CGRect {
        let size = cellSize
        return CGRect(
            x: bounds.minX + CGFloat(column) * size.width,
            y: bounds.minY + CGFloat(row) * size.height,
            width: size.width,
            height: size.height
        )
    }
}
