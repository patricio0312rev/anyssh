import AnySSHCore
import XCTest

@MainActor
final class BiometricGateFlowTests: XCTestCase {
    private let unavailable = ErrorState.secrets(.biometricUnavailable)
    private let cancelled = ErrorState.secrets(.biometricCancelled)

    override func setUp() {
        continueAfterFailure = false
    }

    func testAChangedEnrolmentShowsTheUnavailableCopy() throws {
        let app = launch(reaching: unavailable)

        let element = app.element(withIdentifier: unavailable.accessibilityIdentifier)
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[unavailable.copy.title].exists)
        XCTAssertTrue(app.buttons[unavailable.copy.recoveryLabel].exists)
    }

    func testCancellingThePromptShowsTheCancelledCopyAndNotAGenericFailure() throws {
        let app = launch(reaching: cancelled)

        let element = app.element(withIdentifier: cancelled.accessibilityIdentifier)
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[cancelled.copy.title].exists)
        XCTAssertFalse(
            app.element(withIdentifier: unavailable.accessibilityIdentifier).exists,
            "a cancelled prompt must never be reported as the unavailable state"
        )
        XCTAssertFalse(
            app.element(
                withIdentifier: ErrorState.secrets(.keychainReadDenied).accessibilityIdentifier
            ).exists,
            "a cancelled prompt must never be reported as a denied read"
        )
    }

    func testAStoreThatDoesNotRefuseShowsNoBiometricState() throws {
        let app = XCUIApplication.launched(scenario: ScenarioName.single)

        XCTAssertFalse(
            app.element(withIdentifier: cancelled.accessibilityIdentifier)
                .waitForExistence(timeout: 3)
        )
        XCTAssertFalse(app.element(withIdentifier: unavailable.accessibilityIdentifier).exists)
    }

    private func launch(reaching state: ErrorState) -> XCUIApplication {
        XCUIApplication.launched(scenario: state.stateID)
    }
}
