#if canImport(UIKit)
import UIKit

final class TerminalGestureCanvasView: UIScrollView {
    var alternateScreen = false
    var mouseReporting = false
    var touchMode = false
    var hasSelection = false
    var selectedText = ""
    var selectionEnd = (column: 0, row: 0)
    var selectionRect = CGRect(x: 40, y: 80, width: 160, height: 24)
    var mouseBytes: [UInt8] = [] {
        didSet { mouseLabel.accessibilityValue = String(decoding: mouseBytes, as: UTF8.self) }
    }

    private let mouseLabel = UILabel()
    private var anchor = (column: 0, row: 0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.Code.Platform.canvas
        showsVerticalScrollIndicator = true
        alwaysBounceVertical = true
        isScrollEnabled = true
        keyboardDismissMode = .none
        installMouseLabel()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        preconditionFailure("TerminalGestureCanvasView is created in code")
    }

    func beginSelection(at point: CGPoint) {
        let cell = cell(at: point)
        anchor = cell
        selectionEnd = cell
        hasSelection = true
        selectedText = "https://example.com/path"
        selectionRect = CGRect(x: point.x, y: point.y, width: 24, height: 24)
    }

    func extendSelection(to point: CGPoint) {
        guard hasSelection else { return }
        let cell = cell(at: point)
        selectionEnd = cell
        let width = max(24, abs(point.x - CGFloat(anchor.column * 8)))
        selectionRect = CGRect(
            x: CGFloat(min(anchor.column, cell.column) * 8),
            y: CGFloat(min(anchor.row, cell.row) * 16),
            width: width,
            height: 24
        )
    }

    private func cell(at point: CGPoint) -> (column: Int, row: Int) {
        (
            column: max(0, Int((point.x + contentOffset.x) / 8)),
            row: max(0, Int((point.y + contentOffset.y) / 16))
        )
    }

    private func installMouseLabel() {
        mouseLabel.translatesAutoresizingMaskIntoConstraints = false
        mouseLabel.isAccessibilityElement = true
        mouseLabel.accessibilityIdentifier = UIIdentifier.Terminal.Gestures.mouseReports
        mouseLabel.alpha = 0.01
        addSubview(mouseLabel)
        NSLayoutConstraint.activate([
            mouseLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            mouseLabel.topAnchor.constraint(equalTo: topAnchor),
            mouseLabel.widthAnchor.constraint(equalToConstant: 1),
            mouseLabel.heightAnchor.constraint(equalToConstant: 1),
        ])
        mouseLabel.accessibilityValue = ""
    }
}
#endif
