import Testing

@testable import TerminalEmulator

struct TapFocusGateTests {
    @Test
    func aStillTapOnAStillTerminalShowsTheKeyboard() {
        var gate = TerminalTapFocusGate()
        gate.touchBegan(scrollIsMoving: false)

        #expect(gate.tapShouldFocus(keyboardLocked: false))
    }

    @Test
    func aTapThatStopsAFlingOnlyStopsTheFling() {
        var gate = TerminalTapFocusGate()
        gate.touchBegan(scrollIsMoving: true)

        #expect(!gate.tapShouldFocus(keyboardLocked: false))
    }

    @Test
    func aTouchThatTurnsIntoADragNeverShowsTheKeyboard() {
        var gate = TerminalTapFocusGate()
        gate.touchBegan(scrollIsMoving: false)
        gate.dragBegan()

        #expect(!gate.tapShouldFocus(keyboardLocked: false))
    }

    @Test
    func theNextStillTapAfterAFlingShowsTheKeyboardAgain() {
        var gate = TerminalTapFocusGate()
        gate.touchBegan(scrollIsMoving: true)
        gate.touchBegan(scrollIsMoving: false)

        #expect(gate.tapShouldFocus(keyboardLocked: false))
    }

    @Test
    func aLockedKeyboardIgnoresEveryTap() {
        var gate = TerminalTapFocusGate()
        gate.touchBegan(scrollIsMoving: false)

        #expect(!gate.tapShouldFocus(keyboardLocked: true))
    }
}
