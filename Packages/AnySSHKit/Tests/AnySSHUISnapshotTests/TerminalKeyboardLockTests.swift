#if canImport(UIKit)
import TerminalEmulator
import Testing
import UIKit

@testable import AnySSHUI

@Suite @MainActor struct TerminalKeyboardLockTests {
    private final class FlingingScrollView: UIScrollView {
        var flinging = false
        override var isDecelerating: Bool { flinging }
    }

    private final class EndedTap: UITapGestureRecognizer {
        override var state: UIGestureRecognizer.State {
            get { .ended }
            set {}
        }
    }

    private final class FocusCounter {
        var count = 0
    }

    private func coordinator(
        on scrollView: UIScrollView,
        focuses counter: FocusCounter
    ) -> TerminalInteractionCoordinator {
        let coordinator = TerminalInteractionCoordinator(
            scrollView: scrollView,
            modeProvider: { shiftHeld in
                TerminalGestureMode(
                    alternateScreen: false,
                    mouseReporting: false,
                    touchMode: false,
                    shiftHeld: shiftHeld
                )
            },
            selectionState: { false },
            textProvider: { "" },
            sessionSwitchHandler: {},
            focusHandler: { counter.count += 1 }
        )
        coordinator.install()
        return coordinator
    }

    private func tap(_ coordinator: TerminalInteractionCoordinator) {
        guard let tap = coordinator.tap else { return }
        _ = coordinator.gestureRecognizer(tap, shouldReceive: UITouch())
        coordinator.handleTap(EndedTap())
    }

    @Test func aNewWorkspaceStartsUnlocked() {
        #expect(!TerminalKeyboardLock().isLocked)
    }

    @Test func lockingAndUnlockingFlipsTheState() {
        let lock = TerminalKeyboardLock()

        lock.lock()
        #expect(lock.isLocked)

        lock.unlock()
        #expect(!lock.isLocked)
    }

    @Test func aStillTapShowsTheKeyboard() {
        let counter = FocusCounter()
        let coordinator = coordinator(on: FlingingScrollView(), focuses: counter)

        tap(coordinator)

        #expect(counter.count == 1)
    }

    @Test func aTapThatStopsAFlingDoesNotShowTheKeyboard() {
        let counter = FocusCounter()
        let scrollView = FlingingScrollView()
        scrollView.flinging = true
        let coordinator = coordinator(on: scrollView, focuses: counter)

        tap(coordinator)

        #expect(counter.count == 0)
    }

    @Test func aLockedKeyboardStaysDownOnTap() {
        let counter = FocusCounter()
        let coordinator = coordinator(on: FlingingScrollView(), focuses: counter)
        let lock = TerminalKeyboardLock()
        lock.lock()
        coordinator.keyboardLock = lock

        tap(coordinator)

        #expect(counter.count == 0)
    }

    @Test func unlockingLetsTheNextTapShowTheKeyboard() {
        let counter = FocusCounter()
        let coordinator = coordinator(on: FlingingScrollView(), focuses: counter)
        let lock = TerminalKeyboardLock()
        lock.lock()
        coordinator.keyboardLock = lock
        tap(coordinator)

        lock.unlock()
        tap(coordinator)

        #expect(counter.count == 1)
    }
}
#endif
