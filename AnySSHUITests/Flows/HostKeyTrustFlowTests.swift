import AnySSHCore
import AnySSHUI
import XCTest

@MainActor
final class HostKeyTrustFlowTests: XCTestCase {
    private let firstUse = ErrorState.trust(.firstUse)
    private let rejected = ErrorState.trust(.rejected)
    private let cancelled = ErrorState.trust(.cancelled)
    private let changed = ErrorState.trust(.hostKeyChanged)

    override func setUp() {
        continueAfterFailure = false
    }

    func testFirstUseShowsTheFingerprintAndAcceptingClosesTheSheet() throws {
        let app = try launch(scenario: "unknownHost", reaching: firstUse)

        XCTAssertTrue(app.staticTexts[firstUse.copy.title].exists)
        XCTAssertTrue(app.buttons[UIIdentifier.Trust.accept].exists)
        XCTAssertTrue(app.buttons[UIIdentifier.Trust.reject].exists)
        XCTAssertTrue(app.buttons[UIIdentifier.Trust.cancel].exists)

        let fingerprint = app.element(withIdentifier: UIIdentifier.Trust.offeredFingerprint)
        XCTAssertTrue(fingerprint.exists)
        XCTAssertTrue((fingerprint.value as? String ?? "").hasPrefix("SHA256:"))

        app.buttons[UIIdentifier.Trust.accept].tap()
        XCTAssertFalse(app.element(withIdentifier: firstUse.accessibilityIdentifier).exists)
        XCTAssertFalse(app.element(withIdentifier: rejected.accessibilityIdentifier).exists)
        XCTAssertFalse(app.element(withIdentifier: cancelled.accessibilityIdentifier).exists)
    }

    func testRejectingShowsTheRejectedCopyAndNotTheCancelledOne() throws {
        let app = try launch(scenario: "unknownHost", reaching: firstUse)

        app.buttons[UIIdentifier.Trust.reject].tap()

        let element = app.element(withIdentifier: rejected.accessibilityIdentifier)
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[rejected.copy.title].exists)
        XCTAssertTrue(app.staticTexts[rejected.copy.body].exists)
        XCTAssertTrue(app.buttons[rejected.copy.recoveryLabel].exists)
        XCTAssertFalse(app.element(withIdentifier: cancelled.accessibilityIdentifier).exists)
    }

    func testCancellingShowsTheCancelledCopyAndNotTheRejectedOne() throws {
        let app = try launch(scenario: "unknownHost", reaching: firstUse)

        app.buttons[UIIdentifier.Trust.cancel].tap()

        let element = app.element(withIdentifier: cancelled.accessibilityIdentifier)
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[cancelled.copy.title].exists)
        XCTAssertTrue(app.staticTexts[cancelled.copy.body].exists)
        XCTAssertTrue(app.buttons[cancelled.copy.recoveryLabel].exists)
        XCTAssertFalse(app.element(withIdentifier: rejected.accessibilityIdentifier).exists)
    }

    func testAChangedKeyOffersNoWayToContinue() throws {
        let app = try launch(scenario: "knownAndChanged", reaching: changed)

        XCTAssertTrue(app.staticTexts[changed.copy.title].exists)
        XCTAssertTrue(app.element(withIdentifier: UIIdentifier.Trust.storedFingerprint).exists)
        XCTAssertTrue(app.element(withIdentifier: UIIdentifier.Trust.offeredFingerprint).exists)
        XCTAssertTrue(app.buttons[UIIdentifier.Trust.cancel].exists)
        XCTAssertTrue(app.buttons[UIIdentifier.Trust.forget].exists)
        XCTAssertFalse(app.buttons[UIIdentifier.Trust.accept].exists)
    }

    private func launch(scenario: String, reaching state: ErrorState) throws -> XCUIApplication {
        let app = XCUIApplication.launched(scenario: scenario)

        let element = app.element(withIdentifier: state.accessibilityIdentifier)
        XCTAssertTrue(
            element.waitForExistence(timeout: 10),
            "the \(scenario) scenario did not present \(state.stateID)"
        )
        return app
    }
}
