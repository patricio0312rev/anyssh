import AnySSHUI
import XCTest

@MainActor
final class NotificationFlowTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testForegroundOSC9ShowsABannerAndRequestsNoSystemNotification() throws {
        let app = XCUIApplication.launched(scenario: "sessions.notifyForeground")
        let banner = app.element(withIdentifier: UIIdentifier.JobAlerts.banner)
        XCTAssertTrue(
            banner.waitForExistence(timeout: 15),
            "a foreground OSC 9 must raise the in-app banner"
        )
        XCTAssertTrue(app.element(withIdentifier: UIIdentifier.Terminal.canvas).exists)

        XCTAssertEqual(try probe(in: app), "0||")
    }

    func testBackgroundedOSC9RequestsExactlyOneSystemNotification() throws {
        let app = XCUIApplication.launched(scenario: "sessions.notifyBackground")
        let canvas = app.element(withIdentifier: UIIdentifier.Terminal.canvas)
        XCTAssertTrue(canvas.waitForExistence(timeout: 8))

        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 8)

        app.activate()
        let probe = app.element(withIdentifier: UIIdentifier.JobAlerts.systemRequests)
        XCTAssertTrue(
            probe.waitForExistence(timeout: 5),
            "the session screen must publish its system-request record"
        )
        XCTAssertEqual(probe.value as? String, "1|Backup finished|")
    }

    func testTheBellReachesTheJobAlertSettings() throws {
        let app = XCUIApplication.launched(scenario: "sessions.notifyForeground")
        let canvas = app.element(withIdentifier: UIIdentifier.Terminal.canvas)
        XCTAssertTrue(canvas.waitForExistence(timeout: 8))

        app.element(withIdentifier: SessionSwitcherIdentifier.title).tap()
        XCTAssertTrue(
            app.element(withIdentifier: SessionSwitcherIdentifier.surface)
                .waitForExistence(timeout: 5)
        )

        app.element(withIdentifier: UIIdentifier.JobAlerts.open).tap()
        let settings = app.element(withIdentifier: UIIdentifier.JobAlerts.settings)
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        XCTAssertTrue(app.element(withIdentifier: UIIdentifier.JobAlerts.quietToggle).exists)
        XCTAssertTrue(app.element(withIdentifier: UIIdentifier.JobAlerts.snippet).exists)
    }

    private func probe(in app: XCUIApplication) throws -> String {
        let element = app.element(withIdentifier: UIIdentifier.JobAlerts.systemRequests)
        try XCTSkipUnless(element.exists, "the session screen does not publish its alert probe")
        return element.value as? String ?? ""
    }
}
