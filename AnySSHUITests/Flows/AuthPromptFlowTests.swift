import AnySSHUI
import XCTest

@MainActor
final class AuthPromptFlowTests: XCTestCase {
    private let scenario = "auth.keyboardInteractive"

    override func setUp() {
        continueAfterFailure = false
    }

    func testHiddenAndVisibleFieldsAreTypedAndSubmitted() throws {
        let app = try launch()
        let hidden = app.secureTextFields[UIIdentifier.Auth.field(0)]
        let visible = app.textFields[UIIdentifier.Auth.field(1)]

        XCTAssertTrue(hidden.exists, "the first prompt is not echoed and must be a secure field")
        XCTAssertTrue(visible.exists, "the second prompt is echoed and must be a plain field")

        hidden.tap()
        hidden.typeText("123456")
        visible.tap()
        visible.typeText("phone")
        app.buttons[UIIdentifier.Auth.submit].tap()

        XCTAssertFalse(
            app.element(withIdentifier: UIIdentifier.Auth.sheet).waitForExistence(timeout: 2)
        )
    }

    func testCancellingShowsTheCancellationCopy() throws {
        let app = try launch()
        app.buttons[UIIdentifier.Auth.cancel].tap()

        let refusal = app.element(withIdentifier: "error.auth.keyboardInteractiveCancelled")
        XCTAssertTrue(refusal.waitForExistence(timeout: 5))

        let copy = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] %@", "Verification cancelled")
        )
        XCTAssertTrue(copy.firstMatch.waitForExistence(timeout: 5))
    }

    private func launch() throws -> XCUIApplication {
        let app = XCUIApplication.launched(scenario: scenario)

        let sheet = app.element(withIdentifier: UIIdentifier.Auth.sheet)
        XCTAssertTrue(
            sheet.waitForExistence(timeout: 10),
            "the composition root did not route ANYSSH_SCENARIO=\(scenario) to AuthPromptSheet"
        )
        return app
    }
}
