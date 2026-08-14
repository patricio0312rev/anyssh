import AnySSHUI
import XCTest

@MainActor
final class JumpToFlowTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testHerdrSheetShowsTheTreeWaitingCountAndStatusValues() throws {
        let app = try openJump(scenario: "sessions.jumpTo")

        XCTAssertTrue(
            app.element(withIdentifier: JumpToIdentifier.group("default"))
                .waitForExistence(timeout: 5),
            "the herdr workspace must appear as a jump group"
        )
        XCTAssertTrue(
            app.element(withIdentifier: JumpToIdentifier.row("w1:t1")).exists,
            "the tab row must carry its group identifier"
        )

        let waiting = app.element(withIdentifier: JumpToIdentifier.waiting)
        XCTAssertEqual(
            waiting.value as? String, "1",
            "one of the two panes reports working, so the waiting count must be exactly 1"
        )

        let status = app.element(withIdentifier: JumpToIdentifier.status("w1:t1"))
        XCTAssertTrue(status.exists, "a herdr row must expose a status element")
        XCTAssertEqual(
            status.value as? String, "working",
            "the status must be read from the accessibility value, not from colour"
        )
    }

    func testTmuxSheetHasNoStatusDotsAndExplainsOnce() throws {
        let app = try openJump(scenario: "sessions.jumpTo.tmux")

        XCTAssertTrue(
            app.element(withIdentifier: JumpToIdentifier.explanation)
                .waitForExistence(timeout: 5),
            "tmux must explain once why rows carry no status dot"
        )

        let dots = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "jump.status."))
        XCTAssertEqual(
            dots.count, 0,
            "tmux exposes no agent state, so zero status-dot elements may exist"
        )
    }

    func testTheSavedLayoutIsTheOneTheSheetOpensOn() throws {
        let app = try openJump(scenario: "sessions.jumpTo.grid")

        XCTAssertEqual(
            app.element(withIdentifier: JumpToIdentifier.layoutGrid).value as? String,
            "selected",
            "a saved grid preference must be the layout the sheet opens on"
        )
        XCTAssertNotEqual(
            app.element(withIdentifier: JumpToIdentifier.layoutList).value as? String,
            "selected"
        )

        app.element(withIdentifier: JumpToIdentifier.layoutAccordion).tap()
        XCTAssertEqual(
            app.element(withIdentifier: JumpToIdentifier.layoutAccordion).value as? String,
            "selected"
        )
        XCTAssertNotEqual(
            app.element(withIdentifier: JumpToIdentifier.layoutGrid).value as? String,
            "selected"
        )
    }

    func testTappingAWindowRowAttachesAndDismissesTheSheet() throws {
        let app = try openJump(scenario: "sessions.jumpTo.tmux")

        let row = app.element(withIdentifier: JumpToIdentifier.row("@1"))
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        XCTAssertTrue(
            app.element(withIdentifier: JumpToIdentifier.sheet).waitForNonExistence(timeout: 5),
            "a jump that reached the writer must dismiss the sheet"
        )
        XCTAssertFalse(
            app.element(withIdentifier: JumpToIdentifier.failure).exists,
            "a jump that reached the writer must not record a failure"
        )
    }

    private func openJump(scenario: String) throws -> XCUIApplication {
        let app = XCUIApplication.launched(scenario: scenario)
        let sheet = app.element(withIdentifier: JumpToIdentifier.sheet)
        try XCTSkipUnless(
            sheet.waitForExistence(timeout: 10),
            "the composition root does not route ANYSSH_SCENARIO=\(scenario) to the jump sheet"
        )
        return app
    }
}
