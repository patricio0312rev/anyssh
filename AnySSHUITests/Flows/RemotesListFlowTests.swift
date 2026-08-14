import XCTest

@MainActor
final class RemotesListFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testMockScenarioPopulatesTheRemotesList() {
        let screen = RemotesScreen(app: XCUIApplication.launched(scenario: "default"))

        XCTAssertTrue(screen.list.waitForExistence(timeout: 10))
        XCTAssertTrue(screen.row("workstation").exists)
        XCTAssertTrue(screen.row("build-box").exists)
    }

    func testEmptyScenarioShowsTheEmptyState() {
        let screen = RemotesScreen(app: XCUIApplication.launched(scenario: ScenarioName.empty))

        XCTAssertTrue(screen.emptyState.waitForExistence(timeout: 10))
        XCTAssertFalse(screen.list.exists)
    }
}
