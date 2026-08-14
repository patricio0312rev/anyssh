import XCTest

@MainActor
final class AccessibilityAuditTests: XCTestCase {
    private static let probes: Set<String> = [
        "launch.keychainMigrationRuns",
        "terminal.shortcut.log",
        "terminal.transport.bytes",
        "terminal.gestures.route",
        "terminal.gestures.scrollOffset",
        "terminal.gestures.selectionEnd",
        "terminal.gestures.mouseReports",
        "session.switch.durations",
        "session.byteCounter",
        "jobAlerts.systemRequests",
        "terminal.session.switcher",
    ]

    private static let containerRoles: Set<XCUIElement.ElementType> = [
        .any, .other, .group, .window, .application, .table, .collectionView, .scrollView,
        .navigationBar, .cell, .toolbar, .tabBar,
    ]

    private static let scenarios = [
        ScenarioName.empty,
        ScenarioName.single,
        ScenarioName.mixed,
        ScenarioName.workspace,
        ScenarioName.herdr,
    ]

    func testEveryIdentifiedElementCarriesALabel() throws {
        let axe = try AXeDriver()

        for scenario in Self.scenarios {
            _ = XCUIApplication.launched(scenario: scenario)
            let unlabelled = try axe.elements()
                .filter { !Self.probes.contains($0.identifier) }
                .filter { !Self.containerRoles.contains($0.role) }
                .filter { ($0.label ?? "").trimmingCharacters(in: .whitespaces).isEmpty }
                .filter { ($0.value ?? "").isEmpty }
                .map { $0.identifier }

            XCTAssertTrue(
                unlabelled.isEmpty,
                "\(scenario): identified but unreadable by VoiceOver: \(unlabelled.joined(separator: ", "))"
            )
        }
    }

    func testNoElementIsAnnouncedBySymbolName() throws {
        let axe = try AXeDriver()

        for scenario in Self.scenarios {
            _ = XCUIApplication.launched(scenario: scenario)
            let leaked = try axe.elements()
                .filter { Self.looksLikeASymbolName($0.label) }
                .map { "\($0.identifier) -> \($0.label ?? "")" }

            XCTAssertTrue(
                leaked.isEmpty,
                "\(scenario): SF Symbol names read aloud: \(leaked.joined(separator: ", "))"
            )
        }
    }

    private static func looksLikeASymbolName(_ label: String?) -> Bool {
        guard let label, !label.isEmpty, label.contains(".") else { return false }
        return label.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "." }
            && !label.hasSuffix(".")
    }
}
