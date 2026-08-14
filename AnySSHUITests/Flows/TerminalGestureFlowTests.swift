import AnySSHUI
import XCTest

@MainActor
final class TerminalGestureFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testOneFingerDragScrollsWithoutStartingSelection() throws {
        let app = try launch()
        let canvas = app.element(withIdentifier: UIIdentifier.Terminal.canvas)
        let endProbe = app.element(withIdentifier: UIIdentifier.Terminal.Gestures.selectionEnd)
        let scrollProbe = app.element(withIdentifier: UIIdentifier.Terminal.Gestures.scrollOffset)

        let beforeEnd = endProbe.value as? String ?? "0,0"
        let beforeScroll = scrollProbe.value as? String ?? "0.0"

        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
        let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0)

        let afterEnd = endProbe.value as? String ?? "0,0"
        let afterScroll = scrollProbe.value as? String ?? "0.0"

        XCTAssertEqual(beforeEnd, afterEnd, "a quick drag must not start a selection")
        XCTAssertNotEqual(beforeScroll, afterScroll, "a quick drag must scroll the terminal")
    }

    func testSelectionDragKeepsScrollOffsetStable() throws {
        let app = try launch()
        let canvas = app.element(withIdentifier: UIIdentifier.Terminal.canvas)
        let endProbe = app.element(withIdentifier: UIIdentifier.Terminal.Gestures.selectionEnd)
        let scrollProbe = app.element(withIdentifier: UIIdentifier.Terminal.Gestures.scrollOffset)

        let canvasStart = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.4))
        let mid = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.4))
        let farther = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.4))

        canvasStart.press(
            forDuration: 0.8,
            thenDragTo: mid,
            withVelocity: .slow,
            thenHoldForDuration: 0.1
        )
        let firstEnd = endProbe.value as? String ?? ""
        let scrollAfterCreate = scrollProbe.value as? String ?? "0.0"

        mid.press(forDuration: 0.4, thenDragTo: farther, withVelocity: .slow, thenHoldForDuration: 0.1)
        let secondEnd = endProbe.value as? String ?? ""
        let scrollAfterExtend = scrollProbe.value as? String ?? "0.0"

        XCTAssertNotEqual(firstEnd, "0,0", "long-press drag should create a selection")
        XCTAssertNotEqual(firstEnd, secondEnd, "selection end should move when dragging inside it")
        XCTAssertEqual(scrollAfterCreate, scrollAfterExtend, "selection drag must not scroll")
        XCTAssertTrue(canvas.exists)
    }

    func testOneFingerDragOnBodyDoesNotOpenSessionSwitcher() throws {
        let app = try launch()
        let canvas = app.element(withIdentifier: UIIdentifier.Terminal.canvas)
        let switcher = app.element(withIdentifier: UIIdentifier.Terminal.Gestures.sessionSwitcher)
        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))

        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0)

        XCTAssertFalse(switcher.exists && (switcher.value as? String) == "open")
        XCTAssertTrue(canvas.exists)
    }

    func testSessionSwitchFlowWaitsForAHeaderOrTwoFingerRoute() throws {
        let app = try launch()
        let switcher = app.element(withIdentifier: UIIdentifier.Terminal.Gestures.sessionSwitcher)
        try XCTSkipUnless(
            switcher.exists || app.element(withIdentifier: SessionSwitcherIdentifier.title).exists,
            "the composition root does not expose the session header or switcher route"
        )
    }

    private func launch() throws -> XCUIApplication {
        let app = XCUIApplication.launched(scenario: "terminal.gestures")

        let canvas = app.element(withIdentifier: UIIdentifier.Terminal.canvas)
        try XCTSkipUnless(
            canvas.waitForExistence(timeout: 5),
            "the composition root does not route ANYSSH_SCENARIO=terminal.gestures to a terminal"
        )
        return app
    }
}
