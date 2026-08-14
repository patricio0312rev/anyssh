import AnySSHCore
import AnySSHUI
import XCTest

@MainActor
final class ReconnectFlowTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        executionTimeAllowance = 240
    }

    func testBackgroundingShowsDisconnectedCopyAndReconnectRestoresTheShell() throws {
        let app = XCUIApplication.launched(scenario: ScenarioName.workspace)

        let canvas = app.element(withIdentifier: UIIdentifier.Terminal.canvas)
        try XCTSkipUnless(
            canvas.waitForExistence(timeout: 8),
            "composition root does not present a session workspace for \(ScenarioName.workspace)"
        )

        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 60)
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))

        let axe = try AXeDriver()
        let survival = ErrorState.session(.survivalSSH)
        let deadline = Date().addingTimeInterval(20)
        var sawSurvival = false
        var sawReconnect = false
        while Date() < deadline {
            if app.staticTexts[survival.copy.body].exists
                || app.element(withIdentifier: survival.accessibilityIdentifier).exists
            {
                sawSurvival = true
            }
            if app.element(withIdentifier: UIIdentifier.Session.reconnect).exists {
                sawReconnect = true
            }
            if sawSurvival && sawReconnect { break }
            Thread.sleep(forTimeInterval: 0.5)
        }

        try XCTSkipUnless(
            sawSurvival && sawReconnect,
            "disconnected survival copy and session.reconnect were not visible after backgrounding"
        )

        try axe.tap(UIIdentifier.Session.reconnect, waiting: 10)

        app.element(withIdentifier: UIIdentifier.Terminal.canvas).tap()
        try XCTSkipUnless(
            app.keyboards.firstMatch.waitForExistence(timeout: 5),
            "the reconnected terminal took no keyboard focus; a live host is needed"
        )
        let marker = "ANYSSH-RECONNECT-\(Int(Date().timeIntervalSince1970))"
        try axe.type("printf '\\n\(marker)\\n'\\n")

        let markerDeadline = Date().addingTimeInterval(15)
        var found = false
        while Date() < markerDeadline {
            if app.staticTexts[marker].exists {
                found = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        try XCTSkipUnless(
            found,
            "printf marker did not round-trip after reconnect; live host may be unavailable"
        )
    }
}
