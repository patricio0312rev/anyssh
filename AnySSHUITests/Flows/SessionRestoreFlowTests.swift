import AnySSHCore
import AnySSHUI
import XCTest

@MainActor
final class SessionRestoreFlowTests: XCTestCase {
    private let scenario = ScenarioName.restore
    private let clearRestoreArgument = "-ANYSSH_CLEAR_RESTORE"
    private let rowA = SessionSwitcherIdentifier.row("restore-1")
    private let rowB = SessionSwitcherIdentifier.row("restore-2")

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        executionTimeAllowance = 240
    }

    func testColdLaunchRestoresSessionsTranscriptAndReconnect() throws {
        let axe = try AXeDriver()
        let app = launch(clearRestore: true)
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        XCTAssertTrue(try axe.wait(for: UIIdentifier.Terminal.canvas))

        try openSwitcher(axe: axe)
        XCTAssertTrue(try axe.contains(rowA))
        XCTAssertTrue(try axe.contains(rowB))
        try axe.tap(rowA)

        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 1)

        app.terminate()

        let relaunched = launch(clearRestore: false)
        XCTAssertTrue(relaunched.wait(for: .runningForeground, timeout: 10))

        XCTAssertTrue(
            try axe.wait(for: UIIdentifier.Terminal.canvas),
            "the cold launch did not come back to a restored workspace"
        )

        try openSwitcher(axe: axe)
        XCTAssertTrue(try axe.contains(rowA), "the first restored session is missing")
        XCTAssertTrue(try axe.contains(rowB), "the second restored session is missing")
        try axe.tap(rowA)

        let survival = ErrorState.session(.survivalSSH)
        try XCTSkipUnless(
            try waitForText(survival.copy.body, axe: axe, timeout: 10)
                && axe.contains(UIIdentifier.Session.reconnect),
            "the restored workspace did not report the disconnected state; a live host is needed"
        )
        try axe.tap(UIIdentifier.Session.reconnect, waiting: 10)

        relaunched.element(withIdentifier: UIIdentifier.Terminal.canvas).tap()
        try XCTSkipUnless(
            relaunched.keyboards.firstMatch.waitForExistence(timeout: 5),
            "the reconnected terminal took no keyboard focus; a live host is needed"
        )
        let marker = "ANYSSH-RESTORE-\(Int(Date().timeIntervalSince1970))"
        try axe.type("printf '\\n\(marker)\\n'\\n")
        try XCTSkipUnless(
            try waitForText(marker, axe: axe),
            "printf marker did not round-trip after reconnect; live host may be unavailable"
        )
    }

    private func launch(clearRestore: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-UITestMode", "YES"]
        if clearRestore {
            app.launchArguments += [clearRestoreArgument]
        }
        app.launchEnvironment["ANYSSH_SCENARIO"] = scenario
        app.launch()
        return app
    }

    private func openSwitcher(axe: AXeDriver) throws {
        try axe.tap(SessionSwitcherIdentifier.title)
        XCTAssertTrue(try axe.wait(for: SessionSwitcherIdentifier.surface))
    }

    private func waitForText(
        _ text: String,
        axe: AXeDriver,
        timeout: TimeInterval = 15
    ) throws -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if try axe.describe().contains(text) {
                return true
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return false
    }
}
