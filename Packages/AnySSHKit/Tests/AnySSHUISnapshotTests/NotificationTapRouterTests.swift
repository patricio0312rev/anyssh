import AnySSHCore
import AnySSHMocks
import Foundation
import Sessions
import Testing

@testable import AnySSHUI

@MainActor
@Suite struct NotificationTapRouterTests {
    @Test func tappingExtractsTheCarriedSessionID() {
        let userInfo = [NotificationTapRouter.sessionIDKey: "session-b"]
        #expect(NotificationTapRouter.sessionID(from: userInfo) == SessionID(rawValue: "session-b"))
    }

    @Test func tappingExtractsTheCarriedPaneID() {
        let pane = MuxPaneID(rawValue: "pane-7")
        let userInfo = [NotificationTapRouter.paneIDKey: pane.rawValue]
        #expect(NotificationTapRouter.paneID(from: userInfo) == pane)
    }

    @Test func aNotificationWithoutASessionIDSelectsNothing() {
        #expect(NotificationTapRouter.sessionID(from: [:]) == nil)
        #expect(NotificationTapRouter.sessionID(from: [NotificationTapRouter.sessionIDKey: 42]) == nil)
    }

    @Test func tappingSelectsTheSessionWhoseIDItCarries() async {
        let model = SessionWorkspaceFixture.model()
        let target = model.registry.sessions[1].id
        #expect(model.activeSessionID != target)

        model.select(target)
        for _ in 0..<1_000 where model.activeSessionID != target {
            await Task.yield()
        }

        #expect(model.activeSessionID == target)
    }

    @Test func selectingTheActiveSessionIsANoOp() throws {
        let model = SessionWorkspaceFixture.model()
        let active = try #require(model.activeSessionID)
        model.select(active)
        #expect(model.activeSessionID == active)
    }
}
