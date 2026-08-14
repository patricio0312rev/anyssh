import AnySSHCore
import AnySSHMocks
import Testing

@testable import AnySSHUI

@Suite @MainActor struct MultiplexerPaneListModelTests {
    @Test func attachIgnoresFurtherTapsWhileOneIsInFlight() async throws {
        let writer = GatedDisplayWriter()
        let model = MultiplexerPaneListModel(
            adapter: FixtureMultiplexerAdapter(fixture: .tmuxMain),
            writer: writer
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
