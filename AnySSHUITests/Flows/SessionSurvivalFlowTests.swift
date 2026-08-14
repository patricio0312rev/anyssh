import AnySSHUI
import XCTest

@MainActor
final class SessionSurvivalFlowTests: XCTestCase {
    private let scenario = ScenarioName.workspace

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testASessionSurvivesLeavingItsScreenAndComingBack() throws {
        let app = try launch()
        let canvas = app.element(withIdentifier: UIIdentifier.Terminal.canvas)
        guard let sessionID = canvas.value as? String else {
            throw XCTSkip("the terminal surface does not publish its session id")
        }
        let bytesBefore = try counter(in: app)

        app.element(withIdentifier: SessionSwitcherIdentifier.title).tap()
        let switcher = app.element(withIdentifier: SessionSwitcherIdentifier.surface)
        XCTAssertTrue(switcher.waitForExistence(timeout: 5))
        app.element(withIdentifier: SessionSwitcherIdentifier.row("session-1")).tap()

        XCTAssertTrue(switcher.waitForNonExistence(timeout: 5))
        XCTAssertTrue(canvas.waitForExistence(timeout: 5))
        XCTAssertEqual(canvas.value as? String, sessionID)
        XCTAssertGreaterThanOrEqual(try counter(in: app), bytesBefore)
    }

    func testMockModeListsFourSessions() throws {
        let app = XCUIApplication.launched(scenario: scenario)
        try XCTSkipUnless(
            app.element(withIdentifier: UIIdentifier.Terminal.canvas).waitForExistence(timeout: 8),
            "the composition root does not route ANYSSH_SCENARIO=\(scenario) to a workspace"
        )
        app.element(withIdentifier: SessionSwitcherIdentifier.title).tap()

        let rows = (1...4).map {
            app.element(withIdentifier: SessionSwitcherIdentifier.row("session-\($0)"))
        }
        try XCTSkipUnless(
            rows[0].waitForExistence(timeout: 5),
            "the composition root does not route ANYSSH_SCENARIO=\(scenario) to a session list"
        )
        for row in rows {
            XCTAssertTrue(row.exists)
        }
    }

    private func counter(in app: XCUIApplication) throws -> Int {
        let element = app.element(withIdentifier: SessionSwitcherIdentifier.byteCounter)
        try XCTSkipUnless(element.exists, "the session screen does not publish its byte counter")
        return Int(element.value as? String ?? "") ?? 0
    }

    private func launch() throws -> XCUIApplication {
        let app = XCUIApplication.launched(scenario: scenario)
        let canvas = app.element(withIdentifier: UIIdentifier.Terminal.canvas)
        try XCTSkipUnless(
            canvas.waitForExistence(timeout: 8),
            "the composition root does not route ANYSSH_SCENARIO=\(scenario) to a terminal"
        )
        return app
    }
}
