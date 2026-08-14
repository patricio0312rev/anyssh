#if canImport(UIKit)
import TerminalEmulator
import UIKit

extension TerminalInteractionCoordinator {
    func emitWheel(from start: CGPoint, to point: CGPoint) {
        guard let scrollView else { return }
        let rowHeight = max(scrollView.bounds.height / 24, 1)
        let travelled = Int((point.y - wheelAnchor.y) / rowHeight)
        guard travelled != 0 else { return }
        wheelAnchor.y += CGFloat(travelled) * rowHeight
        let column = max(0, Int(point.x / max(scrollView.bounds.width / 80, 1)))
        let row = max(0, Int(point.y / rowHeight))
        let button: TerminalMouseButton = travelled > 0 ? .wheelUp : .wheelDown
        for _ in 0..<abs(travelled) {
            mouseReportHandler(
                TerminalMouseReport(button: button, column: column, row: row, pressed: true)
            )
        }
    }

    func emitScrollKeys(to point: CGPoint) {
        guard let scrollView else { return }
        let rowHeight = max(scrollView.bounds.height / 24, 1)
        let travelled = Int((point.y - wheelAnchor.y) / rowHeight)
        guard travelled != 0 else { return }
        wheelAnchor.y += CGFloat(travelled) * rowHeight
        let key: TerminalKey = travelled > 0 ? .up : .down
        scrollKeyHandler(key, abs(travelled))
    }

    func beginWheel(at point: CGPoint) {
        wheelAnchor = point
    }

    func emitMouse(at point: CGPoint, pressed: Bool) {
        guard let scrollView else { return }
        let column = max(0, Int(point.x / max(scrollView.bounds.width / 80, 1)))
        let row = max(0, Int(point.y / max(scrollView.bounds.height / 24, 1)))
        if let last = lastReportedCell, last.column == column, last.row == row, pressed {
            return
        }
        lastReportedCell = (column, row)
        mouseReportHandler(
            TerminalMouseReport(button: .primary, column: column, row: row, pressed: pressed)
        )
    }
}
#endif
