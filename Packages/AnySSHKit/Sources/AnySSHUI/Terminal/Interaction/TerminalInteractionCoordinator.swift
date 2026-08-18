#if canImport(UIKit)
import TerminalEmulator
@preconcurrency import UIKit

@MainActor
public final class TerminalInteractionCoordinator: NSObject,
    @MainActor UIEditMenuInteractionDelegate,
    UIGestureRecognizerDelegate
{
    public typealias ModeProvider = (Bool) -> TerminalGestureMode
    public typealias SelectionState = () -> Bool
    public typealias TextProvider = () -> String
    public typealias SelectionGeometry = () -> (endColumn: Int, endRow: Int, menuRect: CGRect)
    public typealias PointHandler = (CGPoint) -> Void
    public typealias SessionSwitchHandler = () -> Void
    public typealias MouseReportHandler = (TerminalMouseReport) -> Void
    public typealias ScrollKeyHandler = (TerminalKey, Int) -> Void
    public typealias CopyHandler = (String) -> Void
    public typealias GestureHandler = (GestureSlot) -> Void
    public typealias CellLocator = (CGPoint) -> (column: Int, row: Int)
    public typealias CellSizeProvider = () -> (width: CGFloat, height: CGFloat)
    public typealias FocusHandler = () -> Void

    weak var scrollView: UIScrollView?
    private let modeProvider: ModeProvider
    let selectionState: SelectionState
    private let textProvider: TextProvider
    private let selectionGeometry: SelectionGeometry
    let beginSelection: PointHandler
    let extendSelection: PointHandler
    let sessionSwitchHandler: SessionSwitchHandler
    let mouseReportHandler: MouseReportHandler
    let scrollKeyHandler: ScrollKeyHandler
    var sidewaysDrag = false
    private let copyHandler: CopyHandler
    let gestureHandler: GestureHandler
    let cellAt: CellLocator
    let cellSize: CellSizeProvider
    let focusHandler: FocusHandler
    let probe: TerminalSelectionProbe
    let arbitration: TerminalScrollArbitration

    private var editMenuInteraction: UIEditMenuInteraction?
    var oneFingerPan: UIPanGestureRecognizer?
    var longPress: UILongPressGestureRecognizer?
    var tap: UITapGestureRecognizer?
    var activeRoute: TerminalGestureRoute = .scrollback
    var lastReportedCell: (column: Int, row: Int)?
    var wheelAnchor: CGPoint = .zero
    var wheelTravelled = false
    var didEmitClick = false
    var remoteMouseHeld = false
    var selectionDragActive = false
    var claimsScrollForSwipe = false

    var isSelecting: Bool { selectionState() || selectionDragActive }
    var currentRoute: TerminalGestureRoute { activeRoute }

    public init(
        scrollView: UIScrollView,
        modeProvider: @escaping ModeProvider,
        selectionState: @escaping SelectionState,
        textProvider: @escaping TextProvider,
        selectionGeometry: @escaping SelectionGeometry = { (0, 0, .zero) },
        beginSelection: @escaping PointHandler = { _ in },
        extendSelection: @escaping PointHandler = { _ in },
        sessionSwitchHandler: @escaping SessionSwitchHandler,
        mouseReportHandler: @escaping MouseReportHandler = { _ in },
        scrollKeyHandler: @escaping ScrollKeyHandler = { _, _ in },
        copyHandler: @escaping CopyHandler = { text in SystemClipboardPasteboard().write(text) },
        gestureHandler: @escaping GestureHandler = { _ in },
        cellAt: @escaping CellLocator = { point in
            (max(0, Int(point.x / 8)), max(0, Int(point.y / 16)))
        },
        cellSize: @escaping CellSizeProvider = { (8, 16) },
        focusHandler: @escaping FocusHandler = {},
        probe: TerminalSelectionProbe = TerminalSelectionProbe()
    ) {
        self.scrollView = scrollView
        self.modeProvider = modeProvider
        self.selectionState = selectionState
        self.textProvider = textProvider
        self.selectionGeometry = selectionGeometry
        self.beginSelection = beginSelection
        self.extendSelection = extendSelection
        self.sessionSwitchHandler = sessionSwitchHandler
        self.mouseReportHandler = mouseReportHandler
        self.scrollKeyHandler = scrollKeyHandler
        self.copyHandler = copyHandler
        self.gestureHandler = gestureHandler
        self.cellAt = cellAt
        self.cellSize = cellSize
        self.focusHandler = focusHandler
        self.probe = probe
        arbitration = TerminalScrollArbitration(scrollView: scrollView)
    }

    public func install() {
        guard let scrollView, oneFingerPan == nil else { return }
        scrollView.keyboardDismissMode = .none
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.decelerationRate = .fast
        probe.install(on: scrollView)
        let editMenu = UIEditMenuInteraction(delegate: self)
        scrollView.addInteraction(editMenu)
        editMenuInteraction = editMenu
        oneFingerPan = addPan(touches: 1, action: #selector(handleOneFingerPan))
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.delegate = self
        scrollView.addGestureRecognizer(tapRecognizer)
        tap = tapRecognizer
        let press = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        press.minimumPressDuration = 0.45
        press.allowableMovement = 12
        press.delegate = self
        scrollView.addGestureRecognizer(press)
        longPress = press
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(handleScrollPan))
        publishProbeState()
    }

    @objc private func handleScrollPan(_ gesture: UIPanGestureRecognizer) {
        publishProbeState()
    }

    public func dismissKeyboard() {
        scrollView?.endEditing(true)
    }

    func resolvedRoute(for gesture: UIGestureRecognizer) -> TerminalGestureRoute {
        TerminalGesturePolicy.route(for: modeProvider(gesture.modifierFlags.contains(.shift)))
    }

    func markRoute(_ route: TerminalGestureRoute) {
        activeRoute = route
    }

    func publishProbeState() {
        guard let scrollView else { return }
        let geometry = selectionGeometry()
        probe.update(
            selectionEndColumn: geometry.endColumn,
            selectionEndRow: geometry.endRow,
            scrollOffsetY: scrollView.contentOffset.y,
            route: activeRoute.rawValue
        )
    }

    func presentEditMenu() {
        guard let editMenuInteraction else { return }
        let geometry = selectionGeometry()
        let point = CGPoint(x: geometry.menuRect.midX, y: geometry.menuRect.minY)
        editMenuInteraction.presentEditMenu(
            with: UIEditMenuConfiguration(identifier: nil, sourcePoint: point)
        )
        publishProbeState()
    }

    func selectionText() -> String { textProvider() }

    func copySelectionText(_ text: String) {
        copyHandler(text)
    }

    func selectionMenuRect() -> CGRect {
        let rect = selectionGeometry().menuRect
        return rect == .zero ? (scrollView?.bounds ?? .zero) : rect
    }

    private func addPan(touches: Int, action: Selector) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer(target: self, action: action)
        pan.minimumNumberOfTouches = touches
        pan.maximumNumberOfTouches = touches
        pan.delegate = self
        pan.cancelsTouchesInView = false
        scrollView?.addGestureRecognizer(pan)
        return pan
    }
}
#endif
