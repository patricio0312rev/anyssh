import AnySSHUI
import XCTest

@MainActor
final class RemotesCRUDFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testCreatingAHostAddsItToAPopulatedList() throws {
        let axe = try AXeDriver()
        _ = XCUIApplication.launched(scenario: ScenarioName.single)

        XCTAssertTrue(try axe.wait(for: UIIdentifier.Remote.list))
        XCTAssertEqual(try rows(axe), ["remote.row.workstation"])

        try axe.tap(UIIdentifier.Remote.add)
        XCTAssertTrue(try axe.wait(for: UIIdentifier.RemoteForm.host))
        try axe.tap(UIIdentifier.RemoteForm.host)
        try axe.type("edge.example.net")
        try axe.tap(UIIdentifier.RemoteForm.username)
        try axe.type("deploy")
        try axe.tap(UIIdentifier.RemoteForm.save)

        XCTAssertTrue(try axe.wait(for: UIIdentifier.Remote.list))
        XCTAssertEqual(try rows(axe).count, 2)
        XCTAssertTrue(try axe.describe().contains("deploy@edge.example.net"))
    }

    func testEditingAHostRewritesTheRowItCameFrom() throws {
        let axe = try AXeDriver()
        _ = XCUIApplication.launched(scenario: ScenarioName.single)

        XCTAssertTrue(try axe.wait(for: UIIdentifier.Remote.list))
        try revealActions(on: "remote.row.workstation")
        XCTAssertTrue(try axe.wait(for: UIIdentifier.Remote.editRow("workstation")))
        try axe.tap(UIIdentifier.Remote.editRow("workstation"))
        XCTAssertTrue(try axe.wait(for: UIIdentifier.RemoteForm.name))

        try axe.tap(UIIdentifier.RemoteForm.name)
        try axe.selectAll()
        try axe.type("Studio")
        try axe.tap(UIIdentifier.RemoteForm.save)

        XCTAssertTrue(try axe.wait(for: UIIdentifier.Remote.list))
        XCTAssertEqual(
            try rows(axe), ["remote.row.workstation"],
            "editing must replace the host rather than add a second one"
        )
        XCTAssertTrue(try axe.describe().contains("Studio"))
    }

    func testReorderingByDragPersistsTheNewOrderThroughTheStore() throws {
        let axe = try AXeDriver()
        _ = XCUIApplication.launched(scenario: ScenarioName.mixed)

        XCTAssertTrue(try axe.wait(for: UIIdentifier.Remote.list))
        let before = try rows(axe)
        XCTAssertEqual(
            before,
            ["remote.row.workstation", "remote.row.build-box", "remote.row.edge-node"]
        )

        try axe.tap(UIIdentifier.Remote.edit)
        guard let last = try axe.frame(of: "remote.row.edge-node"),
            let first = try axe.frame(of: "remote.row.workstation")
        else {
            return XCTFail("the reorder mode did not report row frames")
        }

        try axe.drag(
            from: CGPoint(x: last.maxX - 14, y: last.midY),
            to: CGPoint(x: first.maxX - 14, y: first.minY + 2)
        )

        let after = try rows(axe)
        XCTAssertEqual(
            after,
            ["remote.row.edge-node", "remote.row.workstation", "remote.row.build-box"],
            "the drag did not reorder the list, the tree reports \(after)"
        )
    }

    func testDeletingAHostRemovesItsRow() throws {
        let axe = try AXeDriver()
        _ = XCUIApplication.launched(scenario: ScenarioName.mixed)

        XCTAssertTrue(try axe.wait(for: UIIdentifier.Remote.list))
        try revealActions(on: "remote.row.build-box")
        try axe.tap(UIIdentifier.Remote.delete("build-box"))
        try axe.tap(UIIdentifier.Remote.deleteConfirm)

        XCTAssertTrue(
            try axe.waitForAbsence(of: UIIdentifier.Remote.row("build-box")),
            "the row is still there after the deletion was confirmed"
        )
        XCTAssertEqual(try rows(axe), ["remote.row.workstation", "remote.row.edge-node"])
    }

    private func revealActions(on identifier: String) throws {
        let row = XCUIApplication().element(withIdentifier: identifier)
        guard row.waitForExistence(timeout: 5) else {
            throw AXeFailure.missing(identifier)
        }
        row.swipeLeft()
    }

    private func rows(_ axe: AXeDriver) throws -> [String] {
        try axe.remoteRows()
    }
}
