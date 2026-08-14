#if canImport(UIKit)
import Testing

@testable import AnySSHUI

@Suite @MainActor struct SessionSwitcherSnapshotTests {
    @Test func listSelectsTheActiveSessionWithTheAccentStroke() {
        ComponentSnapshot.assert(
            SessionSwitcherView(model: SessionSwitcherFixture()) { _ in },
            named: "switcher-list",
            height: 700
        )
    }

    @Test func gridKeepsTheSameSelectionIdiom() {
        ComponentSnapshot.assert(
            SessionSwitcherView(model: SessionSwitcherFixture(isGridMode: true)) { _ in },
            named: "switcher-grid",
            height: 700
        )
    }

    @Test func emptyStatesTheReasonRatherThanBlanking() {
        ComponentSnapshot.assert(
            SessionSwitcherView(model: SessionSwitcherFixture(fixture: "empty")) { _ in },
            named: "switcher-empty",
            height: 700
        )
    }
}
#endif
