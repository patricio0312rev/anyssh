import AnySSHCore
import AnySSHUI
import XCTest

@MainActor
final class DeepLinkFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testAnErrorLinkReachesTheStateItNames() throws {
        let state = ErrorState.transport(.connectionRefused)
        let app = XCUIApplication.launched(scenario: ScenarioName.single)
        XCTAssertTrue(
            app.element(withIdentifier: UIIdentifier.Remote.list).waitForExistence(timeout: 10)
        )

        try SimulatorURL.open("anyssh://error/\(state.stateID)")

        let element = app.element(withIdentifier: state.accessibilityIdentifier)
        XCTAssertTrue(element.waitForExistence(timeout: 10), "anyssh://error/ reached no screen")
        XCTAssertTrue(app.staticTexts[state.copy.title].exists)
        XCTAssertTrue(app.buttons[state.copy.recoveryLabel].exists)
    }

    func testASecondLinkReplacesTheStateOnScreen() throws {
        let first = ErrorState.mux(.absent)
        let second = ErrorState.git(.missing)
        let app = XCUIApplication.launched(scenario: ScenarioName.single)
        XCTAssertTrue(
            app.element(withIdentifier: UIIdentifier.Remote.list).waitForExistence(timeout: 10)
        )

        try SimulatorURL.open("anyssh://error/\(first.stateID)")
        XCTAssertTrue(
            app.element(withIdentifier: first.accessibilityIdentifier)
                .waitForExistence(timeout: 10)
        )

        try SimulatorURL.open("anyssh://error/\(second.stateID)")
        XCTAssertTrue(
            app.element(withIdentifier: second.accessibilityIdentifier)
                .waitForExistence(timeout: 10)
        )
        XCTAssertFalse(app.element(withIdentifier: first.accessibilityIdentifier).exists)
    }

    func testAScenarioLinkReachesTheTrustSheet() throws {
        let app = XCUIApplication.launched(scenario: ScenarioName.single)
        XCTAssertTrue(
            app.element(withIdentifier: UIIdentifier.Remote.list).waitForExistence(timeout: 10)
        )

        try SimulatorURL.open("anyssh://scenario/unknownHost")

        XCTAssertTrue(
            app.element(withIdentifier: ErrorState.trust(.firstUse).accessibilityIdentifier)
                .waitForExistence(timeout: 10)
        )
        XCTAssertTrue(app.buttons[UIIdentifier.Trust.accept].exists)
    }

    func testAScenarioLinkIsIgnoredInLiveMode() throws {
        let app = XCUIApplication()
        app.launch()

        let empty = app.element(withIdentifier: UIIdentifier.Remote.empty)
        XCTAssertTrue(
            empty.waitForExistence(timeout: 15),
            "live launch did not reach the remotes screen"
        )

        try SimulatorURL.open("anyssh://scenario/hostKeyTrust")

        XCTAssertFalse(
            app.buttons[UIIdentifier.Trust.accept].waitForExistence(timeout: 3),
            "anyssh://scenario reached a trust sheet in a live build"
        )
        XCTAssertTrue(empty.exists)
    }

    func testALinkTheAppDoesNotOwnLeavesTheListAlone() throws {
        let app = XCUIApplication.launched(scenario: ScenarioName.single)
        let list = app.element(withIdentifier: UIIdentifier.Remote.list)
        XCTAssertTrue(list.waitForExistence(timeout: 10))

        try SimulatorURL.open("anyssh://error/nosuch.state")

        XCTAssertTrue(list.exists)
    }
}
