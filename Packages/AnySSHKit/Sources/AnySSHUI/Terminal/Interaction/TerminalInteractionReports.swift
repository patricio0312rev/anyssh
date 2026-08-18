#if canImport(UIKit)
import TerminalEmulator
import UIKit

extension TerminalInteractionCoordinator {
    func emitWheel(from start: CGPoint, to point: CGPoint) {
        let rowHeight = cellSize().height
        let travelled = Int((point.y - wheelAnchor.y) / rowHeight)
        guard travelled != 0 else { return }
        wheelTravelled = true
        wheelAnchor.y += CGFloat(travelled) * rowHeight
        let cell = cellAt(point)
        let button: TerminalMouseButton = travelled > 0 ? .wheelUp : .wheelDown
        for _ in 0..<abs(travelled) {
            mouseReportHandler(
                TerminalMouseReport(button: button, column: cell.column, row: cell.row, pressed: true)
            )
        }
    }

    func emitScrollKeys(to point: CGPoint) {
        let rowHeight = cellSize().height
        let travelled = Int((point.y - wheelAnchor.y) / rowHeight)
        guard travelled != 0 else { return }
        wheelAnchor.y += CGFloat(travelled) * rowHeight
        let key: TerminalKey = travelled > 0 ? .up : .down
        scrollKeyHandler(key, abs(travelled))
    }

    func beginWheel(at point: CGPoint) {
        wheelAnchor = point
        wheelTravelled = false
        didEmitClick = false
    }

    func emitClick(at point: CGPoint) {
        guard !didEmitClick else { return }
        didEmitClick = true
        lastReportedCell = nil
        emitMouse(at: point, pressed: true)
        lastReportedCell = nil
        emitMouse(at: point, pressed: false)
        focusHandler()
    }

    func emitMouse(at point: CGPoint, pressed: Bool) {
        let cell = cellAt(point)
        if let last = lastReportedCell, last.column == cell.column, last.row == cell.row, pressed {
            return
        }
        lastReportedCell = cell
        mouseReportHandler(
            TerminalMouseReport(button: .primary, column: cell.column, row: cell.row, pressed: pressed)
        )
    }
}
#endif
