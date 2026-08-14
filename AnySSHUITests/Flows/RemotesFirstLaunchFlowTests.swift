import AnySSHUI
import XCTest

@MainActor
final class RemotesFirstLaunchFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testTheZeroHostStateCarriesBothItsActions() throws {
        let axe = try AXeDriver()
        _ = XCUIApplication.launched(scenario: ScenarioName.empty)

        XCTAssertTrue(try axe.wait(for: UIIdentifier.Remote.empty))
        let identifiers = try axe.identifiers()
        XCTAssertTrue(identifiers.contains("error.app.noHostsYet"))
        XCTAssertTrue(identifiers.contains(UIIdentifier.Remote.emptyAddHost))
        XCTAssertTrue(identifiers.contains(UIIdentifier.Remote.emptyImportKey))
        XCTAssertFalse(identifiers.contains(UIIdentifier.Remote.list))
    }

    func testAddingTheFirstHostReplacesTheEmptyStateWithItsRow() throws {
        let axe = try AXeDriver()
        _ = XCUIApplication.launched(scenario: ScenarioName.empty)

        XCTAssertTrue(try axe.wait(for: UIIdentifier.Remote.empty))
        XCTAssertTrue(try axe.identifiers(startingWith: "remote.row.").isEmpty)

        try axe.tap(UIIdentifier.Remote.emptyAddHost)
        XCTAssertTrue(try axe.wait(for: UIIdentifier.RemoteForm.host))

        try axe.tap(UIIdentifier.RemoteForm.host)
        try axe.type("build-box.local")
        try axe.tap(UIIdentifier.RemoteForm.username)
        try axe.type("patricio")
        try axe.tap(UIIdentifier.RemoteForm.port)
        try axe.type("2222")

        try axe.tap(UIIdentifier.RemoteForm.save)

        XCTAssertTrue(
            try axe.waitForAbsence(of: UIIdentifier.Remote.empty),
            "the empty state is still on screen after the first host was saved"
        )
        XCTAssertTrue(try axe.wait(for: UIIdentifier.Remote.list))

        let rows = try axe.remoteRows()
        XCTAssertEqual(rows.count, 1, "expected exactly one row, found \(rows)")
        XCTAssertTrue(try axe.describe().contains("dev@build-box.local:2222"))
    }

    func testARefusedPortKeepsTheFormOpenAndSavesNothing() throws {
        let axe = try AXeDriver()
        _ = XCUIApplication.launched(scenario: ScenarioName.empty)

        XCTAssertTrue(try axe.wait(for: UIIdentifier.Remote.empty))
        try axe.tap(UIIdentifier.Remote.emptyAddHost)
        XCTAssertTrue(try axe.wait(for: UIIdentifier.RemoteForm.host))

        try axe.tap(UIIdentifier.RemoteForm.host)
        try axe.type("build-box.local")
        try axe.tap(UIIdentifier.RemoteForm.username)
        try axe.type("patricio")
        try axe.tap(UIIdentifier.RemoteForm.port)
        try axe.type("70000")
        try axe.tap(UIIdentifier.RemoteForm.save)

        XCTAssertTrue(
            try axe.wait(for: UIIdentifier.RemoteForm.message(UIIdentifier.RemoteForm.port))
        )
        XCTAssertTrue(try axe.contains(UIIdentifier.RemoteForm.screen))
        XCTAssertTrue(try axe.identifiers(startingWith: "remote.row.").isEmpty)
    }
}
