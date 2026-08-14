import CoreGraphics

struct DiffGutter: Equatable, Sendable {
    let showsOldNumbers: Bool
    let showsNewNumbers: Bool

    init(rows: [DiffRow]) {
        showsOldNumbers = rows.contains { $0.oldLineNumber != nil }
        showsNewNumbers = rows.contains { $0.newLineNumber != nil }
    }

    var width: CGFloat {
        let columns = (showsOldNumbers ? 1 : 0) + (showsNewNumbers ? 1 : 0)
        return DiffMetrics.lineNumberColumn * CGFloat(columns) + DiffMetrics.markerColumn
    }
}
