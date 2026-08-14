import AnySSHUI
import UIKit
import XCTest

@MainActor
final class ClipboardFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testSelectionCopyWritesPasteboardAndOutboundOSC52() throws {
        let app = XCUIApplication.launched(scenario: "terminal.clipboard")
        let selection = app.element(withIdentifier: UIIdentifier.Terminal.Clipboard.selection)
        try XCTSkipUnless(
            selection.waitForExistence(timeout: 5),
            "the composition root does not route ANYSSH_SCENARIO=terminal.clipboard"
        )

        let copy = app.buttons[UIIdentifier.Terminal.Clipboard.copy]
        XCTAssertTrue(copy.waitForExistence(timeout: 5))
        copy.tap()

        let expected = selection.value as? String ?? selection.label
        XCTAssertFalse(expected.isEmpty, "selection fixture must expose the copied text")

        let local = app.element(withIdentifier: "terminal.clipboard.local")
        XCTAssertTrue(local.waitForExistence(timeout: 5))
        XCTAssertEqual(local.value as? String, expected)

        let outbound = app.element(withIdentifier: "terminal.clipboard.outbound")
        XCTAssertTrue(outbound.waitForExistence(timeout: 5))
        let log = outbound.value as? String ?? outbound.label
        let encoded = Data(expected.utf8).base64EncodedString()
        XCTAssertTrue(log.contains("]52;"), "outbound log missing OSC 52 introducer: \(log)")
        XCTAssertTrue(log.contains(encoded), "outbound log missing base64 payload: \(log)")
    }

    func testTmuxClipboardHintIsDistinctFromDenial() throws {
        let app = XCUIApplication.launched(scenario: "terminal.clipboard.tmux")
        let hint = app.element(withIdentifier: "error.app.tmuxClipboardOff")
        try XCTSkipUnless(
            hint.waitForExistence(timeout: 5),
            "the composition root does not route ANYSSH_SCENARIO=terminal.clipboard.tmux"
        )

        XCTAssertTrue(app.staticTexts["tmux clipboard passthrough is off"].exists)
        let body =
            "tmux is on this host without clipboard passthrough, so remote copies never "
            + "reach this device. Add set -g set-clipboard on to your tmux.conf."
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label == %@", body)).firstMatch.exists,
            "the tmux hint must state why remote copies never arrive"
        )
        XCTAssertFalse(app.element(withIdentifier: "error.app.clipboardDenied").exists)
    }
}
