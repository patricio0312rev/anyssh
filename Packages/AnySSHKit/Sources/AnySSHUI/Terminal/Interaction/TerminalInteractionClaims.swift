#if canImport(UIKit)
import TerminalEmulator
import UIKit

extension TerminalInteractionCoordinator {
    func beginSelectionAt(_ point: CGPoint) {
        beginSelection(point)
        selectionDragActive = true
        activeRoute = .selection
        arbitration.disableForSelection()
        publishProbeState()
    }

    func extendSelectionTo(_ point: CGPoint) {
        extendSelection(point)
    }

    func releaseStuckScrollClaim() {
        arbitration.restoreIfIdle(gestureIsActive: isSelecting || remoteMouseHeld)
    }

    func claimScrollForSelection() {
        arbitration.disableForSelection()
    }

    func finishSelectionDrag() {
        if selectionState() {
            presentEditMenu()
        }
        selectionDragActive = false
        arbitration.restore()
        lastReportedCell = nil
        publishProbeState()
    }

    func noteSessionSwitch() {
        probe.noteSessionSwitch()
        sessionSwitchHandler()
    }

    func handleGesture(_ slot: GestureSlot) {
        gestureHandler(slot)
    }

    func beginSwipeClaim() {
        claimsScrollForSwipe = true
        scrollView?.isScrollEnabled = false
    }

    func endSwipeClaim() {
        guard claimsScrollForSwipe else { return }
        claimsScrollForSwipe = false
        scrollView?.isScrollEnabled = true
    }
}
#endif
