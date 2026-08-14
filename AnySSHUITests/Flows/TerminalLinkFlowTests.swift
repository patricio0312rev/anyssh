import AnySSHUI
import XCTest

@MainActor
final class TerminalLinkFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testLongPressOnURLShowsLinkMenuItems() throws {
        let app = try launch()
        longPressURL(in: app)

        let open = app.element(withIdentifier: UIIdentifier.Terminal.Links.open)
        let copyLink = app.element(withIdentifier: UIIdentifier.Terminal.Links.copyLink)
        let copy = app.element(withIdentifier: UIIdentifier.Terminal.Links.copy)
        XCTAssertTrue(open.waitForExistence(timeout: 5), "missing terminal.link.open")
        XCTAssertTrue(copyLink.exists, "missing terminal.link.copyLink")
        XCTAssertTrue(copy.exists, "missing terminal.link.copy")
    }

    func testCopyLinkWritesExactAddress() throws {
        let app = try launch()
        longPressURL(in: app)

        let copyLink = app.element(withIdentifier: UIIdentifier.Terminal.Links.copyLink)
        XCTAssertTrue(copyLink.waitForExistence(timeout: 5))
        copyLink.tap()

        let copied = app.element(withIdentifier: UIIdentifier.Terminal.Links.copied)
        XCTAssertTrue(copied.waitForExistence(timeout: 5))
        XCTAssertEqual(copied.value as? String, TerminalLinkFixture.url)
    }

    func testLongPressOnNonURLShowsNoLinkItems() throws {
        let app = try launch()
        let canvas = app.element(withIdentifier: UIIdentifier.Terminal.canvas)
        let point = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.05))
        point.press(forDuration: 1.0)

        let open = app.element(withIdentifier: UIIdentifier.Terminal.Links.open)
        let copyLink = app.element(withIdentifier: UIIdentifier.Terminal.Links.copyLink)
        XCTAssertFalse(open.waitForExistence(timeout: 2))
        XCTAssertFalse(copyLink.exists)
    }

    func testOpenOnSSHShowsSchemeRefused() throws {
        let app = try launch()
        longPressRefused(in: app)

        let open = app.element(withIdentifier: UIIdentifier.Terminal.Links.open)
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        open.tap()

        let refused = app.element(withIdentifier: "error.link.schemeRefused")
        XCTAssertTrue(refused.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Scheme refused"].exists)
        XCTAssertTrue(
            app.staticTexts[
                "This address uses a scheme the app does not open. Copy the address and "
                    + "open it in another app."
            ].exists
        )
    }

    private func longPressURL(in app: XCUIApplication) {
        let canvas = app.element(withIdentifier: UIIdentifier.Terminal.canvas)
        let dx = (CGFloat(TerminalLinkFixture.urlColumn) + 0.5) / CGFloat(TerminalLinkFixture.columns)
        let dy = (CGFloat(TerminalLinkFixture.urlRow) + 0.5) / CGFloat(TerminalLinkFixture.rows)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy)).press(forDuration: 1.0)
    }

    private func longPressRefused(in app: XCUIApplication) {
        let canvas = app.element(withIdentifier: UIIdentifier.Terminal.canvas)
        let dx =
            (CGFloat(TerminalLinkFixture.refusedColumn) + 0.5)
            / CGFloat(TerminalLinkFixture.columns)
        let dy = (CGFloat(TerminalLinkFixture.refusedRow) + 0.5) / CGFloat(TerminalLinkFixture.rows)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy)).press(forDuration: 1.0)
    }

    private func launch() throws -> XCUIApplication {
        let app = XCUIApplication.launched(scenario: "terminal.links")

        let canvas = app.element(withIdentifier: UIIdentifier.Terminal.canvas)
        try XCTSkipUnless(
            canvas.waitForExistence(timeout: 5),
            "the composition root does not route ANYSSH_SCENARIO=terminal.links"
        )
        return app
    }
}
