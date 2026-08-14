#if canImport(UIKit)
import TerminalEmulator
import UIKit

final class TerminalLinkGridView: UIView {
    static let fontSize: CGFloat = 11

    private let rows: [LinkRow]
    private let spans: [LinkSpan]
    private let label = UILabel()

    override init(frame: CGRect) {
        rows = TerminalLinkBuffer.rows(from: TerminalLinkFixture.screen)
        spans = LinkScanner.scan(rows: rows)
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityIdentifier = UIIdentifier.Terminal.canvas
        backgroundColor = Theme.Code.Platform.canvas
        label.numberOfLines = 0
        label.font = CodeFont.platformFont(size: TerminalLinkGridView.fontSize)
        label.textColor = Theme.Code.Platform.foreground
        label.text = rows.map(\.text).joined(separator: "\n")
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        preconditionFailure("TerminalLinkGridView is created in code")
    }

    var cellMap: TerminalLinkCellMap {
        TerminalLinkCellMap(
            columns: TerminalLinkFixture.columns,
            rows: TerminalLinkFixture.rows,
            bounds: bounds
        )
    }

    func span(at point: CGPoint) -> LinkSpan? {
        guard let cell = cellMap.cell(at: point) else { return nil }
        return LinkHitTester.span(at: cell.row, column: cell.column, in: spans)
    }

    func point(row: Int, column: Int) -> CGPoint {
        let frame = cellMap.frame(row: row, column: column)
        return CGPoint(x: frame.midX, y: frame.midY)
    }
}
#endif
