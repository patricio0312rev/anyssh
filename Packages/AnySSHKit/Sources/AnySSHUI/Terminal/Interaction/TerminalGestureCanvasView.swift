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
    private let endLabel = UILabel()
    private let scrollLabel = UILabel()
    private var anchor = (column: 0, row: 0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.Code.Platform.canvas
        showsVerticalScrollIndicator = true
        alwaysBounceVertical = true
        isScrollEnabled = true
        keyboardDismissMode = .none
        installProbeLabels()
        let pan = UIPanGestureRecognizer(target: self, action: #selector(noteScroll))
        pan.cancelsTouchesInView = false
        addGestureRecognizer(pan)
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
        publishSelection()
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
        publishSelection()
    }

    private func cell(at point: CGPoint) -> (column: Int, row: Int) {
        (
            column: max(0, Int((point.x + contentOffset.x) / 8)),
            row: max(0, Int((point.y + contentOffset.y) / 16))
        )
    }

    private func publishSelection() {
        endLabel.accessibilityValue = "\(selectionEnd.column),\(selectionEnd.row)"
        scrollLabel.accessibilityValue = String(format: "%.1f", contentOffset.y)
    }

    @objc private func noteScroll(_ gesture: UIPanGestureRecognizer) {
        scrollLabel.accessibilityValue = String(format: "%.1f", contentOffset.y)
    }

    private func installProbeLabels() {
        for (label, id) in [
            (endLabel, UIIdentifier.Terminal.Gestures.selectionEnd),
            (scrollLabel, UIIdentifier.Terminal.Gestures.scrollOffset),
            (mouseLabel, UIIdentifier.Terminal.Gestures.route),
        ] {
            label.translatesAutoresizingMaskIntoConstraints = false
            label.isAccessibilityElement = true
            label.accessibilityIdentifier = id
            label.alpha = 0.01
            addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: leadingAnchor),
                label.topAnchor.constraint(equalTo: topAnchor),
                label.widthAnchor.constraint(equalToConstant: 1),
                label.heightAnchor.constraint(equalToConstant: 1),
            ])
        }
        endLabel.accessibilityValue = "0,0"
        scrollLabel.accessibilityValue = "0.0"
        mouseLabel.accessibilityValue = ""
    }
}
#endif
