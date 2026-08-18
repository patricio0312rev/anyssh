#if canImport(UIKit)
import SwiftTerm
import TerminalEmulator
import UIKit

@MainActor
public final class TerminalGestureBridge {
    public var onSessionSwitch: (() -> Void)?
    public var onMouseReport: (([UInt8]) -> Void)?
    public var onKeyBytes: (([UInt8]) -> Void)?
    public var onCopy: ((String) -> Void)?
    public var onGesture: ((GestureSlot) -> Void)?
    public var onFocus: (() -> Void)?
    public var touchMode = false {
        didSet { view.allowMouseReporting = !touchMode }
    }

    private let view: TerminalView
    private var coordinator: TerminalInteractionCoordinator?
    private let probe = TerminalSelectionProbe()
    private var anchor: Position?

    public init(view: TerminalView) {
        self.view = view
        view.selectionHandleColor = Theme.Code.Platform.selectionHandle
        view.keyboardDismissMode = .none
        view.isScrollEnabled = true
        view.allowMouseReporting = false
    }

    public func install() {
        guard coordinator == nil else { return }
        let coordinator = TerminalInteractionCoordinator(
            scrollView: view,
            modeProvider: { [weak self] shiftHeld in
                self?.mode(shiftHeld: shiftHeld)
                    ?? TerminalGestureMode(
                        alternateScreen: false,
                        mouseReporting: false,
                        touchMode: false,
                        shiftHeld: shiftHeld
                    )
            },
            selectionState: { [weak self] in
                self?.view.hasActiveSelection ?? false
            },
            textProvider: { [weak self] in
                self?.view.getSelection() ?? ""
            },
            selectionGeometry: { [weak self] in
                self?.geometry() ?? (0, 0, .zero)
            },
            beginSelection: { [weak self] point in
                self?.startSelection(at: point)
            },
            extendSelection: { [weak self] point in
                self?.extendSelection(to: point)
            },
            sessionSwitchHandler: { [weak self] in
                self?.onSessionSwitch?()
            },
            mouseReportHandler: { [weak self] report in
                self?.onMouseReport?(report.sgrBytes)
            },
            scrollKeyHandler: { [weak self] key, count in
                self?.sendScrollKey(key, count: count)
            },
            copyHandler: { [weak self] text in
                if let onCopy = self?.onCopy {
                    onCopy(text)
                } else {
                    SystemClipboardPasteboard().write(text)
                }
            },
            gestureHandler: { [weak self] slot in
                self?.onGesture?(slot)
            },
            cellAt: { [weak self] point in
                let hit = self?.cell(at: point) ?? Position(col: 0, row: 0)
                return (hit.col, hit.row)
            },
            cellSize: { [weak self] in
                let size = self?.view.caretFrame.size ?? .zero
                return (max(size.width, 1), max(size.height, 1))
            },
            focusHandler: { [weak self] in
                self?.onFocus?()
                _ = self?.view.becomeFirstResponder()
            },
            probe: probe
        )
        coordinator.install()
        self.coordinator = coordinator
    }

    public func dismissKeyboard() {
        coordinator?.dismissKeyboard()
    }

    private func mode(shiftHeld: Bool) -> TerminalGestureMode {
        let terminal = view.getTerminal()
        return TerminalGestureMode(
            alternateScreen: terminal.isCurrentBufferAlternate,
            mouseReporting: terminal.mouseMode != .off,
            touchMode: touchMode,
            shiftHeld: shiftHeld
        )
    }

    private func startSelection(at point: CGPoint) {
        let hit = cell(at: point)
        anchor = hit
        view.setSelectionRange(start: hit, end: hit)
        view.setNeedsDisplay()
    }

    private func extendSelection(to point: CGPoint) {
        let hit = cell(at: point)
        let start = anchor ?? hit
        view.setSelectionRange(start: start, end: hit)
        view.setNeedsDisplay()
    }

    private func cell(at point: CGPoint) -> Position {
        let cell = view.caretFrame.size
        let width = max(cell.width, 1)
        let height = max(cell.height, 1)
        let col = max(0, Int((point.x + view.contentOffset.x) / width))
        let row = max(0, Int((point.y + view.contentOffset.y) / height))
        return Position(col: col, row: row)
    }

    private func geometry() -> (endColumn: Int, endRow: Int, menuRect: CGRect) {
        guard view.hasActiveSelection, let selection = view.selection else {
            return (0, 0, .zero)
        }
        let end = selection.end
        let start = selection.start
        let cell = view.caretFrame.size
        let cellWidth = max(cell.width, 1)
        let cellHeight = max(cell.height, 1)
        let width =
            selection.isMultiLine
            ? view.bounds.width
            : CGFloat(max(1, end.col - start.col)) * cellWidth
        let height = CGFloat(max(1, end.row - start.row + 1)) * cellHeight
        let rect = CGRect(
            x: CGFloat(start.col) * cellWidth - view.contentOffset.x,
            y: CGFloat(start.row) * cellHeight - view.contentOffset.y,
            width: width,
            height: height
        )
        return (end.col, end.row, rect)
    }
    private func sendScrollKey(_ key: TerminalKey, count: Int) {
        var mode = TerminalInputMode()
        mode.applicationCursor = view.getTerminal().applicationCursor
        var input = TerminalInput(mode: mode)
        let bytes = input.send(key)
        for _ in 0..<count {
            onKeyBytes?(bytes)
        }
    }
}

#endif
