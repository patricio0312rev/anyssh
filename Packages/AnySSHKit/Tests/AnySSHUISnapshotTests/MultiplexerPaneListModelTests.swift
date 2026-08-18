import AnySSHCore
import AnySSHMocks
import Testing

@testable import AnySSHUI

@Suite @MainActor struct MultiplexerPaneListModelTests {
    @Test func aDetachedTerminalTypesTheAttachCommandForThePane() async throws {
        let connection = MockRemoteConnection()
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let model = MultiplexerPaneListModel(
            adapter: adapter,
            writer: connection,
            probe: { .detached }
        )
        await model.load()
        let session = try #require(model.sessions.first)
        let pane = try #require(model.snapshot(for: session.id)?.panes.first)
        #expect(await model.attach(to: session.id, from: pane.id))
        #expect(model.lastOutcome == .attached)
        #expect(
            await connection.displayWrites == [
                Array(("'tmux' attach-session -t '$1' \\; select-pane -t '%1'\r").utf8)
            ]
        )
        #expect(await adapter.focusLog.targets.first?.pane == pane.id)
    }

    @Test func anAttachedTerminalOnlyFocusesThePane() async throws {
        let connection = MockRemoteConnection()
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxMain)
        let model = MultiplexerPaneListModel(
            adapter: adapter,
            writer: connection,
            probe: { .attached(MuxSessionID(rawValue: "$1")) }
        )
        await model.load()
        let session = try #require(model.sessions.first)
        let pane = try #require(model.snapshot(for: session.id)?.panes.first)
        #expect(await model.attach(to: session.id, from: pane.id))
        #expect(model.lastOutcome == .focused)
        #expect(await connection.displayWrites.isEmpty)
        #expect(await adapter.focusLog.targets.count == 1)
    }

    @Test func anUnreadableTerminalNeverGetsTheAttachCommand() async throws {
        let connection = MockRemoteConnection()
        let model = MultiplexerPaneListModel(
            adapter: FixtureMultiplexerAdapter(fixture: .tmuxMain),
            writer: connection
        )
        await model.load()
        let session = try #require(model.sessions.first)
        let pane = try #require(model.snapshot(for: session.id)?.panes.first)
        #expect(await model.attach(to: session.id, from: pane.id))
        #expect(model.lastOutcome == .focused)
        #expect(await connection.displayWrites.isEmpty)
    }

    @Test func attachIgnoresFurtherTapsWhileOneIsInFlight() async throws {
        let writer = GatedDisplayWriter()
        let model = MultiplexerPaneListModel(
            adapter: FixtureMultiplexerAdapter(fixture: .tmuxMain),
            writer: writer,
            probe: { .detached }
        )
        await model.load()
        let session = try #require(model.sessions.first)
        let pane = try #require(model.snapshot(for: session.id)?.panes.first)
        let first = Task { await model.attach(to: session.id, from: pane.id) }
        try await waitUntil { await writer.hasWritten }

        #expect(model.attachingPaneID == pane.id)
        #expect(model.isAttaching)
        #expect(await model.attach(to: session.id, from: pane.id) == false)
        #expect(model.attachFailure == nil)

        await writer.release()
        #expect(await first.value)
        #expect(model.attachingPaneID == nil)
        #expect(await writer.writes.count == 1)
    }

    @Test func aStoppedSessionDoesNotHideTheRunningOne() async throws {
        let model = MultiplexerPaneListModel(adapter: StoppedSessionMuxAdapter())
        await model.load()
        #expect(model.sessions.map(\.name) == [StoppedSessionMuxAdapter.runningName])
        let session = try #require(model.sessions.first)
        #expect(model.snapshot(for: session.id)?.panes.count == 1)
        #expect(model.failureState == nil)
    }

    @Test func everySessionFailingKeepsTheFailure() async {
        let model = MultiplexerPaneListModel(adapter: EveryStoppedMuxAdapter())
        await model.load()
        #expect(model.sessions.isEmpty)
        #expect(model.failureState == .command(.failed))
    }

    @Test func attachKeepsTheFailureForTheListToShow() async throws {
        let model = MultiplexerPaneListModel(
            adapter: FixtureMultiplexerAdapter(fixture: .tmuxMain)
        )
        await model.load()
        let session = try #require(model.sessions.first)
        let pane = try #require(model.snapshot(for: session.id)?.panes.first)
        #expect(await model.attach(to: session.id, from: pane.id) == false)
        #expect(model.attachFailure == .mux(.attachTargetVanished))
        #expect(model.attachingPaneID == nil)
    }
}
