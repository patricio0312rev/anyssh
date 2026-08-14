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
