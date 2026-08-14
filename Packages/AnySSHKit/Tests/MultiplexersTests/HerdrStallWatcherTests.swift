import AnySSHCore
import Testing

@testable import AnySSHMocks
@testable import Multiplexers

@Suite struct HerdrStallWatcherTests {
    @Test func notifiesOnceForBlockedAndDoneTransitions() async {
        let scheduler = RecordingNotificationScheduler()
        let watcher = HerdrStallWatcher(sessionID: Self.sessionID, scheduler: scheduler)
        await watcher.ingest(Self.snapshot(status: "working"))
        await watcher.ingest(Self.snapshot(status: "blocked"))
        await watcher.ingest(Self.snapshot(status: "blocked"))
        await watcher.ingest(Self.snapshot(status: "done"))

        let requests = await scheduler.requests
        #expect(requests.map { $0.paneID } == [Self.paneID, Self.paneID])
        #expect(requests.map { $0.alert.title } == ["Claude", "Claude"])
    }

    @Test func blockedAtStartupIsNotReported() async {
        let scheduler = RecordingNotificationScheduler()
        let watcher = HerdrStallWatcher(sessionID: Self.sessionID, scheduler: scheduler)
        await watcher.ingest(Self.snapshot(status: "blocked"))

        #expect(await scheduler.requests.isEmpty)
    }

    private static let sessionID = SessionID(rawValue: "session")
    private static let paneID = MuxPaneID(rawValue: "pane")

    private static func snapshot(status: String) -> MuxSnapshot {
        let session = MuxSession(id: MuxSessionID(rawValue: "mux"), name: "main", isAttached: true)
        let group = MuxGroup(
            id: MuxGroupID(rawValue: "group"), sessionID: session.id, title: "main", isActive: true
        )
        let pane = MuxPane(
            id: paneID, groupID: group.id, title: "Claude", workingDirectory: nil,
            isActive: true, agentStatus: status, repositoryRoot: nil
        )
        return MuxSnapshot(session: session, groups: [group], panes: [pane])
    }
}
