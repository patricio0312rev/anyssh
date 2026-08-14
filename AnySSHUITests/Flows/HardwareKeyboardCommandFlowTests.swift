import AnySSHUI
import Foundation
import XCTest

@MainActor
final class HardwareKeyboardCommandFlowTests: XCTestCase {
    private let titles = [
        "dev@workstation: ~/Sites/anyssh",
        "ci@build-box: tmux ci",
        "root@edge-node",
        "dev@workstation: ~/tmp",
    ]

    private let expectedCommandIDs = [
        "app.newConnection",
        "app.closeSession",
        "session.next",
        "session.previous",
        "session.activateOne",
        "session.activateTwo",
        "session.activateThree",
        "session.activateFour",
        "session.activateFive",
        "session.activateSix",
        "session.activateSeven",
        "session.activateEight",
        "session.activateNine",
        "app.openSwitcher",
        "app.openJumpTo",
        "app.openChanges",
        "app.paste",
        "app.toggleKeyboard",
        "app.commandPalette",
    ]

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testCommandOneThroughFourSwitchSessionsWithZeroTransportBytes() throws {
        let app = XCUIApplication.launched(scenario: ScenarioName.workspace)
        let axe = try AXeDriver()

        for index in 0..<4 {
            try keyCombo(
                modifiers: [HardwareKeyCode.leftCommand.rawValue],
                key: HardwareKeyCode.one.rawValue + UInt16(index)
            )
            XCTAssertTrue(
                try wait(axe: axe, contains: titles[index]),
                "after Cmd+\(index + 1) the tree must report \(titles[index])"
            )
        }

        let transport = app.element(withIdentifier: HardwareKeyboardProbe.transportBytesID)
        XCTAssertTrue(transport.waitForExistence(timeout: 2))
        XCTAssertEqual(
            probeText(transport), "[]",
            "session switching must never write bytes to the transport"
        )
    }

    func testCommandKOpensThePaletteFiltersAndActivatesTheSelectedCommand() throws {
        let app = XCUIApplication.launched(scenario: ScenarioName.workspace)
        let axe = try AXeDriver()

        try keyCombo(
            modifiers: [HardwareKeyCode.leftCommand.rawValue],
            key: HardwareKeyCode.k.rawValue
        )
        XCTAssertTrue(try axe.wait(for: CommandPaletteIdentifier.surface))

        let description = try axe.describe()
        for id in expectedCommandIDs {
            XCTAssertTrue(
                description.contains(CommandPaletteIdentifier.row(id)),
                "the palette must list \(id)"
            )
        }

        try axe.type("open")
        XCTAssertTrue(
            try wait(axe: axe, contains: CommandPaletteIdentifier.row("app.openSwitcher")),
            "typing 'open' must filter to the open commands"
        )
        let filtered = try axe.describe()
        XCTAssertFalse(
            filtered.contains(CommandPaletteIdentifier.row("app.newConnection")),
            "a title without 'open' must be filtered out"
        )
        XCTAssertFalse(
            filtered.contains(CommandPaletteIdentifier.row("session.activateOne")),
            "a session command must be filtered out"
        )

        try keyCombo(key: HardwareKeyCode.down.rawValue)
        try keyCombo(key: HardwareKeyCode.down.rawValue)
        try keyCombo(key: HardwareKeyCode.enter.rawValue)

        XCTAssertTrue(
            try axe.wait(for: SessionSwitcherIdentifier.surface),
            "Return must run the selected command, which opens the switcher"
        )
        XCTAssertEqual(app.state, .runningForeground)
    }

    func testDisabledCommandIsListedAndDoesNotRunOnEnter() throws {
        let app = XCUIApplication.launched(scenario: ScenarioName.workspace)
        let axe = try AXeDriver()

        try keyCombo(
            modifiers: [HardwareKeyCode.leftCommand.rawValue],
            key: HardwareKeyCode.k.rawValue
        )
        XCTAssertTrue(try axe.wait(for: CommandPaletteIdentifier.surface))

        try axe.type("5")
        let row = app.element(withIdentifier: CommandPaletteIdentifier.row("session.activateFive"))
        XCTAssertTrue(row.waitForExistence(timeout: 2), "Session 5 must stay listed")
        XCTAssertFalse(
            row.isEnabled,
            "a command whose predicate is false must carry the disabled trait"
        )
        XCTAssertTrue(
            row.label.contains("4 sessions open"),
            "the disabled row must show why it is disabled, got \(row.label)"
        )

        try keyCombo(key: HardwareKeyCode.enter.rawValue)

        XCTAssertTrue(
            app.element(withIdentifier: CommandPaletteIdentifier.surface).exists,
            "Return on a disabled command must not run it or dismiss the palette"
        )
        XCTAssertTrue(row.exists, "the disabled row must remain listed")
    }

    private func keyCombo(modifiers: [UInt16] = [], key: UInt16) throws {
        try HardwareKeyInput.send(modifiers: modifiers, key: key)
    }

    private func wait(axe: AXeDriver, contains expected: String) throws -> Bool {
        for _ in 0..<40 {
            if try axe.describe().contains(expected) { return true }
            usleep(250_000)
        }
        return false
    }

    private func probeText(_ element: XCUIElement) -> String {
        if let value = element.value as? String, !value.isEmpty { return value }
        return element.label
    }
}
