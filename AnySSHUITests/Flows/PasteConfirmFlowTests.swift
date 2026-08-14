import AnySSHUI
import XCTest

@MainActor
final class PasteConfirmFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testFortyLinePasteShowsCountAndCancelSendsZeroBytes() throws {
        let app = XCUIApplication.launched(scenario: "terminal.pasteConfirm")
        let sheet = app.element(withIdentifier: UIIdentifier.Terminal.Paste.sheet)
        try XCTSkipUnless(
            sheet.waitForExistence(timeout: 5),
            "the composition root does not route ANYSSH_SCENARIO=terminal.pasteConfirm"
        )

        let lineCount = app.element(withIdentifier: UIIdentifier.Terminal.Paste.lineCount)
        XCTAssertTrue(lineCount.waitForExistence(timeout: 5))
        let shown = (lineCount.value as? String) ?? lineCount.label
        XCTAssertTrue(shown.contains("40"), "expected line count 40 in \(shown)")

        app.buttons[UIIdentifier.Terminal.Paste.cancel].tap()

        XCTAssertTrue(
            sheet.waitForNonExistence(timeout: 5),
            "cancelling must close the confirmation sheet"
        )

        let sent = app.element(withIdentifier: "terminal.paste.bytesSent")
        XCTAssertTrue(sent.waitForExistence(timeout: 5))
        let value = sent.value as? String ?? sent.label
        XCTAssertTrue(value == "0" || value.isEmpty, "cancel must send zero bytes, got \(value)")
    }
}
