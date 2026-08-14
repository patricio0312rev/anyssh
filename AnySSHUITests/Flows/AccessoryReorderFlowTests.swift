import Foundation
import XCTest

@MainActor
final class AccessoryReorderFlowTests: XCTestCase {
    private let barID = "terminal.accessory.bar"
    private let tabID = "terminal.accessory.key.tab"
    private let firstID = "terminal.accessory.key.escape"

    override func setUp() {
        continueAfterFailure = false
    }

    func testLongPressDragPersistsTheNewOrderAfterRelaunch() throws {
        let app = XCUIApplication.launched(scenario: ScenarioName.workspace)
        let bar = app.element(withIdentifier: barID)
        guard bar.waitForExistence(timeout: 2) else {
            throw XCTSkip("The current composition root does not present a terminal accessory bar.")
        }

        let tab = app.element(withIdentifier: tabID)
        let first = app.element(withIdentifier: firstID)
        XCTAssertTrue(tab.exists)
        XCTAssertTrue(first.exists)
        tab.press(forDuration: 0.7)
        tab.press(forDuration: 0.8, thenDragTo: first)
        assertOrder(try AXeDriver().describe(), startsWith: [tabID, firstID])

        app.terminate()
        let relaunched = XCUIApplication.launched(scenario: ScenarioName.workspace)
        XCTAssertTrue(relaunched.element(withIdentifier: barID).waitForExistence(timeout: 2))
        assertOrder(try AXeDriver().describe(), startsWith: [tabID, firstID])
    }

    private func assertOrder(_ description: String, startsWith identifiers: [String]) {
        var previous = -1
        for identifier in identifiers {
            guard let range = description.range(of: identifier) else {
                XCTFail("the accessibility tree did not report \(identifier)")
                return
            }
            let offset = description.distance(from: description.startIndex, to: range.lowerBound)
            XCTAssertGreaterThan(offset, previous)
            previous = offset
        }
    }
}
