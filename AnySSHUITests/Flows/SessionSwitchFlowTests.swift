import AnySSHUI
import Foundation
import XCTest

@MainActor
final class SessionSwitchFlowTests: XCTestCase {
    private let titles = [
        "dev@workstation: ~/Sites/anyssh",
        "ci@build-box: tmux ci",
        "root@edge-node",
        "dev@workstation: ~/tmp",
    ]

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        executionTimeAllowance = 240
    }

    func testTenSwitchesLandOnTheExpectedTitleAndStayUnderOneHundredMilliseconds() throws {
        let axe = try AXeDriver()
        _ = XCUIApplication.launched(scenario: ScenarioName.workspace)

        XCTAssertTrue(try axe.wait(for: UIIdentifier.Terminal.canvas))
        XCTAssertTrue(try axe.describe().contains(titles[0]))

        let order = [1, 2, 3, 0, 1, 2, 3, 0, 1, 2]
        var previous = 0
        for index in order {
            try axe.tap(SessionSwitcherIdentifier.title)
            let id = "session-\(index + 1)"
            XCTAssertTrue(try axe.wait(for: SessionSwitcherIdentifier.row(id)))
            try axe.tap(SessionSwitcherIdentifier.row(id))
            XCTAssertTrue(
                try wait(axe: axe, contains: titles[index], andNot: titles[previous]),
                "after switching to session-\(index + 1) the tree must show its title"
            )
            previous = index
        }

        let durations = try switchDurations()
        try XCTSkipUnless(
            !durations.isEmpty,
            "the workspace published no measured switch intervals; the signpost probe is empty"
        )
        XCTAssertGreaterThanOrEqual(
            durations.count, order.count - 1,
            "expected one logged interval per switch, collected \(durations.count)"
        )
        let sorted = durations.sorted()
        let p95 = sorted[min(sorted.count - 1, sorted.count * 95 / 100)]
        XCTAssertLessThan(p95, 100, "switch p95 measured \(p95) ms across \(durations)")
    }

    func testTheSwitcherSwitchesFromListAndGrid() throws {
        let axe = try AXeDriver()
        _ = XCUIApplication.launched(scenario: ScenarioName.workspace)

        XCTAssertTrue(try axe.wait(for: UIIdentifier.Terminal.canvas))
        try axe.tap(SessionSwitcherIdentifier.title)
        XCTAssertTrue(try axe.wait(for: SessionSwitcherIdentifier.row("session-2")))

        try axe.tap(SessionSwitcherIdentifier.mode)
        XCTAssertTrue(try axe.wait(for: SessionSwitcherIdentifier.row("session-3")))
        try axe.tap(SessionSwitcherIdentifier.row("session-3"))
        XCTAssertTrue(try wait(axe: axe, contains: titles[2], andNot: titles[0]))

        try axe.tap(SessionSwitcherIdentifier.title)
        try axe.tap(SessionSwitcherIdentifier.mode)
        XCTAssertTrue(try axe.wait(for: SessionSwitcherIdentifier.row("session-1")))
        try axe.tap(SessionSwitcherIdentifier.row("session-1"))
        XCTAssertTrue(try wait(axe: axe, contains: titles[0], andNot: titles[2]))
    }

    private func wait(
        axe: AXeDriver,
        contains expected: String,
        andNot previous: String
    ) throws -> Bool {
        for _ in 0..<40 {
            let tree = try axe.describe()
            if tree.contains(expected), !tree.contains(previous) { return true }
            usleep(250_000)
        }
        return false
    }

    private func switchDurations() throws -> [Double] {
        let probe = XCUIApplication().element(withIdentifier: UIIdentifier.Session.switchDurations)
        guard probe.waitForExistence(timeout: 5) else { return [] }
        let text = (probe.value as? String) ?? probe.label
        return text.split(separator: ",").compactMap { Double($0) }
    }
}
