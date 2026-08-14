import AnySSHCore
import AnySSHUI
import XCTest

@MainActor
final class SessionRestoreLaunchTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testKeychainMigratorRunsExactlyOncePerLaunch() throws {
        let app = XCUIApplication.launched(scenario: ScenarioName.single)
        let probe = app.element(withIdentifier: UIIdentifier.Launch.keychainMigrationRuns)
        XCTAssertTrue(probe.waitForExistence(timeout: 10))
        XCTAssertEqual(probe.label, "1")

        app.terminate()

        let relaunched = XCUIApplication.launched(scenario: ScenarioName.single)
        let again = relaunched.element(withIdentifier: UIIdentifier.Launch.keychainMigrationRuns)
        XCTAssertTrue(again.waitForExistence(timeout: 10))
        XCTAssertEqual(again.label, "1")
    }

    func testErrorLinkReachesTrustFirstUse() throws {
        let state = ErrorState.trust(.firstUse)
        let app = XCUIApplication.launched(scenario: ScenarioName.single)
        XCTAssertTrue(
            app.element(withIdentifier: UIIdentifier.Remote.list).waitForExistence(timeout: 10)
        )

        try SimulatorURL.open("anyssh://error/\(state.stateID)")

        let element = app.element(withIdentifier: state.accessibilityIdentifier)
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[state.copy.title].exists)
        XCTAssertTrue(app.buttons[state.copy.recoveryLabel].exists)
    }
}
