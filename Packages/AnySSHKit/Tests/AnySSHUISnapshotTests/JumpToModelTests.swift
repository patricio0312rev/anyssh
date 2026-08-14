import AnySSHCore
import AnySSHMocks
import Foundation
import Testing

@testable import AnySSHUI

@Suite @MainActor struct JumpToModelTests {
    @Test func groupStatusTakesTheWorstPaneState() {
        let session = MuxSession(id: MuxSessionID(rawValue: "s"), name: "s", isAttached: true)
        let group = MuxGroup(
            id: MuxGroupID(rawValue: "g"),
            sessionID: session.id,
            title: "g",
            isActive: false
        )
        func snapshot(_ statuses: [String?]) -> MuxSnapshot {
            MuxSnapshot(
                session: session,
                groups: [group],
                panes: statuses.enumerated().map { index, status in
                    MuxPane(
                        id: MuxPaneID(rawValue: "p\(index)"),
                        groupID: group.id,
                        title: "p\(index)",
                        workingDirectory: nil,
                        isActive: false,
                        agentStatus: status,
                        repositoryRoot: nil
                    )
                }
            )
        }

        #expect(JumpTreeBuilder.status(of: group, in: snapshot(["working", "idle"])) == .waiting("working"))
        #expect(JumpTreeBuilder.status(of: group, in: snapshot(["idle", "blocked"])) == .waiting("blocked"))
        #expect(JumpTreeBuilder.status(of: group, in: snapshot(["idle", "done"])) == .finished("idle"))
        #expect(JumpTreeBuilder.status(of: group, in: snapshot([])) == .unknown)
        #expect(JumpTreeBuilder.status(of: group, in: snapshot(["unknown"])) == .unknown)
        #expect(JumpTreeBuilder.status(of: group, in: snapshot(["unrecognised"])) == .unknown)
    }

    @Test func waitingCountSumsWaitingRowsAcrossSessions() {
        let sessions = [
            JumpSession(
                id: MuxSessionID(rawValue: "a"),
                name: "a",
                groups: [
                    row("a1", "one", status: .waiting("working")),
                    row("a2", "two", status: .finished("idle")),
                ]
            ),
            JumpSession(
                id: MuxSessionID(rawValue: "b"),
                name: "b",
                groups: [
                    row("b1", "three", status: .unknown),
                    row("b2", "four", status: .waiting("blocked")),
                ]
            ),
        ]
        let model = JumpToModel(sessions: sessions, kind: .herdr)
        #expect(model.waitingCount == 2)
        #expect(model.showsStatus)
    }

    @Test func tmuxShowsNoStatus() {
        let model = JumpToModel(
            sessions: [JumpSession(id: MuxSessionID(rawValue: "s"), name: "s", groups: [])],
            kind: .tmux
        )
        #expect(!model.showsStatus)
        #expect(model.waitingCount == 0)
    }

    @Test func layoutPreferenceRoundTripsAndFallsBackOnCorruption() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "jump-layout-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(JumpLayoutPreference.load(from: directory) == .list)
        #expect(JumpLayoutPreference.load(from: nil) == .list)

        JumpLayoutPreference.save(.grid, to: directory)
        #expect(JumpLayoutPreference.load(from: directory) == .grid)

        try Data("not an envelope".utf8).write(to: JumpLayoutPreference.fileURL(in: directory))
        #expect(JumpLayoutPreference.load(from: directory) == .list)
    }

    @Test func jumpWritesTheAdaptersAttachCommand() async throws {
        let connection = MockRemoteConnection(connectionID: ConnectionID(rawValue: "jump"))
        let model = JumpToModel(
            adapter: FixtureMultiplexerAdapter(fixture: .tmuxMain),
            directory: nil,
            writer: connection
        )
        await model.load()
        let row = try #require(model.sessions.first?.groups.first)
        let sent = await model.jump(to: row)
        #expect(sent)
        let writes = await connection.displayWrites
        let expected = Array(
            ("'tmux' attach-session -t '$1' \\; select-window -t '@1'\r").utf8
        )
        #expect(writes.last == expected)
    }

    @Test func jumpIgnoresFurtherTapsWhileOneIsInFlight() async throws {
        let writer = GatedDisplayWriter()
        let model = JumpToModel(
            adapter: FixtureMultiplexerAdapter(fixture: .tmuxMain),
            directory: nil,
            writer: writer
        )
        await model.load()
        let row = try #require(model.sessions.first?.groups.first)
        let first = Task { await model.jump(to: row) }
        try await waitUntil { await writer.hasWritten }

        #expect(model.jumpingRowID == row.id)
        #expect(model.isJumping)
        #expect(await model.jump(to: row) == false)
        #expect(await model.jump(to: row) == false)
        #expect(model.jumpFailure == nil)

        await writer.release()
        #expect(await first.value)
        #expect(model.jumpingRowID == nil)
        #expect(await writer.writes.count == 1)
    }

    @Test func jumpKeepsTheFailureForTheSheetToShow() async throws {
        let model = JumpToModel(
            adapter: FixtureMultiplexerAdapter(fixture: .tmuxMain),
            directory: nil,
            writer: nil
        )
        await model.load()
        let row = try #require(model.sessions.first?.groups.first)
        #expect(await model.jump(to: row) == false)
        #expect(model.jumpFailure == .mux(.attachTargetVanished))
        #expect(model.jumpingRowID == nil)
    }

    @Test func buildKeepsOnlySessionsWithSnapshots() {
        let listed = [
            MuxSession(id: MuxSessionID(rawValue: "kept"), name: "kept", isAttached: true),
            MuxSession(id: MuxSessionID(rawValue: "dropped"), name: "dropped", isAttached: false),
        ]
        let kept = MuxSession(id: MuxSessionID(rawValue: "kept"), name: "kept", isAttached: true)
        let group = MuxGroup(
            id: MuxGroupID(rawValue: "g"),
            sessionID: kept.id,
            title: "g",
            isActive: true
        )
        let snapshots = [
            kept.id: MuxSnapshot(
                session: kept,
                groups: [group],
                panes: [
                    MuxPane(
                        id: MuxPaneID(rawValue: "p1"),
                        groupID: group.id,
                        title: "p1",
                        workingDirectory: nil,
                        isActive: true,
                        agentStatus: nil,
                        repositoryRoot: nil
                    )
                ]
            )
        ]
        let built = JumpTreeBuilder.build(sessions: listed, snapshots: snapshots)
        #expect(built.map(\.id.rawValue) == ["kept"])
        #expect(built.first?.groups.first?.paneCount == 1)
    }

    private func row(_ id: String, _ title: String, status: JumpAgentStatus) -> JumpRow {
        JumpRow(
            group: MuxGroup(
                id: MuxGroupID(rawValue: id),
                sessionID: MuxSessionID(rawValue: "s"),
                title: title,
                isActive: false
            ),
            status: status,
            paneCount: 1
        )
    }
}
