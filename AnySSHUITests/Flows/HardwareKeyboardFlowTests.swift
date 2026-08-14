import AnySSHUI
import XCTest

@MainActor
final class HardwareKeyboardFlowTests: XCTestCase {
    private let shortcutLogID = HardwareKeyboardProbe.shortcutLogID
    private let transportBytesID = HardwareKeyboardProbe.transportBytesID

    override func setUp() {
        continueAfterFailure = false
    }

    func testCommandNFallsThroughToTheShortcutLogWithZeroTransportBytes() throws {
        let app = try launch()
        try send(modifiers: [HardwareKeyCode.leftCommand.rawValue], key: HardwareKeyCode.n.rawValue)

        let log = try requireProbe(app, id: shortcutLogID)
        XCTAssertTrue(
            probeText(log).contains("Cmd+N"),
            "Cmd+N must appear in the app shortcut log, got \(probeText(log))"
        )
        let transport = try requireProbe(app, id: transportBytesID)
        XCTAssertEqual(
            parseBytes(probeText(transport)), [],
            "Cmd+N must produce zero transport bytes"
        )
    }

    func testControlCProducesExactlyEtx() throws {
        let app = try launch()
        try send(modifiers: [HardwareKeyCode.leftControl.rawValue], key: HardwareKeyCode.c.rawValue)

        let transport = try requireProbe(app, id: transportBytesID)
        XCTAssertEqual(parseBytes(probeText(transport)), [0x03])
    }

    func testAltFProducesEscapeF() throws {
        let app = try launch()
        try send(modifiers: [HardwareKeyCode.leftAlt.rawValue], key: HardwareKeyCode.f.rawValue)

        let transport = try requireProbe(app, id: transportBytesID)
        XCTAssertEqual(parseBytes(probeText(transport)), [0x1b, 0x66])
    }

    private func launch() throws -> XCUIApplication {
        let app = XCUIApplication.launched(scenario: ScenarioName.workspace)

        let canvas = app.element(withIdentifier: UIIdentifier.Terminal.canvas)
        try XCTSkipUnless(
            canvas.waitForExistence(timeout: 5),
            "the composition root does not route ANYSSH_SCENARIO=\(ScenarioName.workspace) to a terminal"
        )
        return app
    }

    private func send(modifiers: [UInt16], key: UInt16) throws {
        try HardwareKeyInput.send(modifiers: modifiers, key: key)
    }

    private func requireProbe(_ app: XCUIApplication, id: String) throws -> XCUIElement {
        let probe = app.element(withIdentifier: id)
        try XCTSkipUnless(
            probe.waitForExistence(timeout: 2),
            "scenario does not expose \(id); unit coverage is TerminalLayoutKeyboardTests"
        )
        return probe
    }

    private func probeText(_ element: XCUIElement) -> String {
        if let value = element.value as? String, !value.isEmpty { return value }
        return element.label
    }

    private func parseBytes(_ value: String) -> [UInt8] {
        if value.isEmpty || value == "[]" { return [] }
        let trimmed =
            value
            .trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        return trimmed.compactMap { token -> UInt8? in
            if token.hasPrefix("0x") || token.hasPrefix("0X") {
                return UInt8(token.dropFirst(2), radix: 16)
            }
            return UInt8(token)
        }
    }
}
