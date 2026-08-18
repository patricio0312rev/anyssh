import Testing

@testable import TerminalEmulator

struct ClickArbiterTests {
    @Test
    func everyCleanTapEmitsItsOwnClick() {
        var arbiter = TerminalClickArbiter()
        var emitted: [Bool] = []

        for _ in 0..<3 {
            arbiter.touchBegan()
            emitted.append(arbiter.tapEnded())
        }

        #expect(emitted == [true, true, true])
    }

    @Test
    func aShortPanEmitsOnceAndSwallowsTheTapThatFollows() {
        var arbiter = TerminalClickArbiter()
        arbiter.touchBegan()
        arbiter.panBegan()

        let atPanEnd = arbiter.panEnded(travelled: false)
        let atTapEnd = arbiter.tapEnded()

        #expect(atPanEnd)
        #expect(!atTapEnd)
    }

    @Test
    func aTravelledPanEmitsNothing() {
        var arbiter = TerminalClickArbiter()
        arbiter.touchBegan()
        arbiter.panBegan()

        let atPanEnd = arbiter.panEnded(travelled: true)
        let atTapEnd = arbiter.tapEnded()

        #expect(!atPanEnd)
        #expect(!atTapEnd)
    }

    @Test
    func aTapAfterATravelledPanEmitsAgain() {
        var arbiter = TerminalClickArbiter()
        arbiter.touchBegan()
        arbiter.panBegan()
        _ = arbiter.panEnded(travelled: true)

        arbiter.touchBegan()
        let emitted = arbiter.tapEnded()

        #expect(emitted)
    }

    @Test
    func aLongAlternatingSequenceEmitsOnceEachTouch() {
        var arbiter = TerminalClickArbiter()
        var emitted = 0

        for index in 0..<8 {
            arbiter.touchBegan()
            if index.isMultiple(of: 2) {
                arbiter.panBegan()
                if arbiter.panEnded(travelled: false) { emitted += 1 }
            }
            if arbiter.tapEnded() { emitted += 1 }
        }

        #expect(emitted == 8)
    }

    @Test
    func aSecondTapWithinOneTouchStaysSilent() {
        var arbiter = TerminalClickArbiter()
        arbiter.touchBegan()

        let first = arbiter.tapEnded()
        let second = arbiter.tapEnded()

        #expect(first)
        #expect(!second)
    }
}
