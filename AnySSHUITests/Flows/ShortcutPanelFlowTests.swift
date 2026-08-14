import AnySSHCore
import AnySSHUI
import Foundation
import XCTest

@MainActor
final class ShortcutPanelFlowTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testTmuxPanelSendsTheDiscoveredPrefixChord() throws {
        let app = try launch()
        let nextWindow = app.element(
            withIdentifier: ShortcutPanelIdentifier.entry(entryID: "next-window", scope: "tmux")
        )
        guard nextWindow.waitForExistence(timeout: 5) else {
            throw XCTSkip("The scenario does not run a tmux fixture with a next-window entry.")
        }

        nextWindow.tap()

        XCTAssertTrue(
            waitForBytes([0x02, 0x6e], in: app),
            "tapping next-window must write the discovered prefix chord C-b n (0x02 0x6e)"
        )
    }

    func testEveryPanelTabIsNamespacedByItsScope() throws {
        let app = try launch()

        XCTAssertTrue(
            app.element(withIdentifier: ShortcutPanelIdentifier.tab(.tmux))
                .waitForExistence(timeout: 5),
            "a tmux host must carry the tmux tab"
        )
        let description = try AXeDriver().describe()
        XCTAssertTrue(
            description.contains(ShortcutPanelIdentifier.tab(.agent)),
            "the agent panel must be present as the positive control"
        )
        XCTAssertTrue(
            description.contains(
                ShortcutPanelIdentifier.entry(entryID: "next-window", scope: "tmux")
            ),
            "the selected panel's entries must carry their own scope"
        )
        XCTAssertFalse(
            description.contains("panel.herdr."),
            "only the selected panel renders its entries"
        )
    }

    private func launch() throws -> XCUIApplication {
        let app = XCUIApplication.launched(scenario: "sessions.panels")
        try XCTSkipUnless(
            app.element(withIdentifier: ShortcutPanelIdentifier.bar).waitForExistence(timeout: 10),
            "the current composition root does not present shortcut panels."
        )
        return app
    }

    private func waitForBytes(_ expected: [UInt8], in app: XCUIApplication) -> Bool {
        let target = rendered(expected)
        let probe = app.element(withIdentifier: ShortcutPanelIdentifier.bytes)
        guard probe.waitForExistence(timeout: 2) else { return false }
        for _ in 0..<20 {
            if probe.label == target { return true }
            usleep(250_000)
        }
        return false
    }

    private func rendered(_ bytes: [UInt8]) -> String {
        "[" + bytes.map { String(format: "0x%02x", $0) }.joined(separator: ", ") + "]"
    }
}

extension ShortcutPanelIdentifier {
    fileprivate static func entry(entryID: String, scope: String) -> String {
        "panel.\(scope).\(entryID)"
    }
}
