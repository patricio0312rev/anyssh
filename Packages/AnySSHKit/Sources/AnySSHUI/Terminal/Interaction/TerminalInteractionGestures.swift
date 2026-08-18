#if canImport(UIKit)
import TerminalEmulator
import UIKit

extension TerminalInteractionCoordinator {
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: scrollView)
        let route = resolvedRoute(for: gesture)
        if route == .remoteApp {
            switch gesture.state {
            case .began:
                remoteMouseHeld = true
                claimScrollForSelection()
                emitMouse(at: point, pressed: true)
            case .ended, .cancelled, .failed:
                releaseRemoteMouse(at: point)
            default:
                break
            }
            return
        }
        guard gesture.state == .began else { return }
        beginSelectionAt(point)
    }

    private func releaseRemoteMouse(at point: CGPoint) {
        guard remoteMouseHeld else { return }
        remoteMouseHeld = false
        emitMouse(at: point, pressed: false)
        finishSelectionDrag()
    }

    @objc func handleOneFingerPan(_ gesture: UIPanGestureRecognizer) {
        let route = resolvedRoute(for: gesture)
        let selecting = isSelecting
        if gesture.state == .began, !selecting {
            let velocity = gesture.velocity(in: nil)
            sidewaysDrag = SessionSwitchGesturePolicy.isSideways(
                velocityX: velocity.x, velocityY: velocity.y
            )
            if sidewaysDrag { beginSwipeClaim() }
        }
        if sidewaysDrag {
            if gesture.state == .ended {
                let translation = gesture.translation(in: nil)
                if let direction = SessionSwitchGesturePolicy.direction(
                    dx: translation.x, dy: translation.y
                ) {
                    if let slot = SessionSwitchGesturePolicy.slot(direction) {
                        handleGesture(slot)
                    }
                }
            }
            if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
                sidewaysDrag = false
                endSwipeClaim()
            }
            return
        }
        markRoute(selecting ? .selection : route)
        let point = gesture.location(in: scrollView)
        switch gesture.state {
        case .began:
            beginOneFinger(route: route, selecting: selecting, at: point)
        case .changed:
            changeOneFinger(route: route, selecting: selecting, at: point)
        case .ended, .cancelled, .failed:
            endOneFinger(route: route, selecting: selecting, at: point)
            endSwipeClaim()
        default:
            break
        }
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        guard !isSelecting, !remoteMouseHeld else { return }
        let point = gesture.location(in: scrollView)
        let route = resolvedRoute(for: gesture)
        if TerminalGesturePolicy.shouldReportClick(route: route, didTravel: wheelTravelled) {
            emitClick(at: point)
        } else {
            focusHandler()
        }
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === tap || gestureRecognizer === longPress {
            return true
        }
        guard gestureRecognizer === oneFingerPan else { return true }
        releaseStuckScrollClaim()
        let next = resolvedRoute(for: gestureRecognizer)
        markRoute(next)
        return TerminalGesturePolicy.dragShouldBegin(route: next, selectionActive: isSelecting)
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        if gestureRecognizer === longPress { return other === oneFingerPan }
        if gestureRecognizer === tap { return other === oneFingerPan }
        if gestureRecognizer === oneFingerPan {
            if isSelecting || currentRoute != .scrollback {
                return other !== scrollView?.panGestureRecognizer
            }
            return true
        }
        return true
    }

    private func beginOneFinger(route: TerminalGestureRoute, selecting: Bool, at point: CGPoint) {
        if selecting {
            claimScrollForSelection()
            extendSelectionTo(point)
        } else if route == .remoteApp || route == .remoteKeys {
            claimScrollForSelection()
            beginWheel(at: point)
        } else if route == .selection {
            claimScrollForSelection()
            beginSelectionAt(point)
            extendSelectionTo(point)
        }
        publishProbeState()
    }

    private func changeOneFinger(route: TerminalGestureRoute, selecting: Bool, at point: CGPoint) {
        if selecting {
            claimScrollForSelection()
            extendSelectionTo(point)
        } else if remoteMouseHeld {
            emitMouse(at: point, pressed: true)
        } else if route == .remoteApp {
            emitWheel(from: point, to: point)
        } else if route == .remoteKeys {
            emitScrollKeys(to: point)
        }
        publishProbeState()
    }

    private func endOneFinger(route: TerminalGestureRoute, selecting: Bool, at point: CGPoint) {
        if TerminalGesturePolicy.shouldReportClick(route: route, didTravel: wheelTravelled),
            !selecting, !remoteMouseHeld
        {
            emitClick(at: point)
        }
        releaseRemoteMouse(at: point)
        finishSelectionDrag()
        wheelTravelled = false
    }
}
#endif
