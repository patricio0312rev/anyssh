import TerminalEmulator
import Testing

@Suite struct SwipeDirectionTests {
    @Test func aShortDriftNamesNoDirection() {
        #expect(SessionSwitchGesturePolicy.direction(dx: 12, dy: 9) == nil)
    }

    @Test func aSidewaysSwipeWithVerticalDriftStaysSideways() {
        #expect(SessionSwitchGesturePolicy.direction(dx: -120, dy: 40) == .left)
    }

    @Test func anAmbiguousDiagonalIsDiscarded() {
        #expect(SessionSwitchGesturePolicy.direction(dx: 60, dy: 55) == nil)
    }

    @Test func aVerticalSwipeIsStillVertical() {
        #expect(SessionSwitchGesturePolicy.direction(dx: 10, dy: -90) == .up)
        #expect(SessionSwitchGesturePolicy.direction(dx: 10, dy: 90) == .down)
    }

    @Test func aSidewaysFlickIsRecognisedFromItsVelocity() {
        #expect(SessionSwitchGesturePolicy.isSideways(velocityX: -800, velocityY: 120))
        #expect(!SessionSwitchGesturePolicy.isSideways(velocityX: 200, velocityY: 900))
        #expect(!SessionSwitchGesturePolicy.isSideways(velocityX: 300, velocityY: 260))
    }

    @Test func aHorizontalSwipePicksTheSlot() {
        #expect(SessionSwitchGesturePolicy.slot(.left) == .swipeLeft)
        #expect(SessionSwitchGesturePolicy.slot(.right) == .swipeRight)
        #expect(SessionSwitchGesturePolicy.slot(.up) == nil)
        #expect(SessionSwitchGesturePolicy.slot(.down) == nil)
    }
}
