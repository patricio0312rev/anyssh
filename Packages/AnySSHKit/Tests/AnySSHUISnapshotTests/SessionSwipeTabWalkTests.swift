import AnySSHCore
import AnySSHMocks
import Sessions
import Testing

@testable import AnySSHUI

@Suite @MainActor struct SessionSwipeTabWalkTests {
    @Test func aTabWalkStepsThroughTheTabsBeforeTheAppSessions() async throws {
        let model = SessionWorkspaceFixture.model()
        let toasts = StatusToastCenter()
        model.statusToasts = toasts
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "tmux")
        let adapter = SwipeRingMuxAdapter(names: ["alpha"], groupTitles: ["code", "tests"])
        try await bind(Self.alpha, on: model, for: sessionID, using: adapter)

        #expect(model.swipeTarget(.forward) == .muxGroup(Self.alphaTests))

        model.hop(tabToward: .forward)
        try await waitUntil { !model.isHoppingMuxSession }

        #expect(model.sessionMuxGroupIDs[sessionID] == Self.alphaTests)
        #expect(
            await adapter.focusLog.targets == [
                MuxTarget(session: Self.alpha, group: Self.alphaTests)
            ]
        )
        #expect(toasts.items.map(\.severity) == [.success])
        #expect(toasts.items.first?.title == "Switched to tests")
        #expect(model.swipeTarget(.forward) == .appSession(model.registry.ids[1]))
    }

    @Test func aTabWalkWrapsInBothDirectionsOnALoneSession() async throws {
        let model = SessionWorkspaceFixture.model("single")
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "tmux")
        let adapter = SwipeRingMuxAdapter(names: ["alpha"], groupTitles: ["code", "tests"])
        try await bind(Self.alpha, on: model, for: sessionID, using: adapter)

        #expect(model.swipeTarget(.backward) == .muxGroup(Self.alphaTests))

        model.hop(tabToward: .backward)
        try await waitUntil { !model.isHoppingMuxSession }

        #expect(model.swipeTarget(.forward) == .muxGroup(Self.alphaCode))
        #expect(model.swipeTarget(.backward) == .muxGroup(Self.alphaCode))
    }

    @Test func theActiveTabAnchorsTheRingAndWrapsBackwardIntoTheAppSegment() async throws {
        let model = SessionWorkspaceFixture.model()
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "tmux")
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxCluster)
        try await bind(Self.main, on: model, for: sessionID, using: adapter)

        #expect(model.swipeTarget(.forward) == .muxGroup(Self.window2))
        #expect(model.swipeTarget(.backward) == .appSession(model.registry.ids[3]))
    }

    @Test func aTmuxTabHopFocusesTheWindowAndToastsItsTitle() async throws {
        let model = SessionWorkspaceFixture.model()
        let toasts = StatusToastCenter()
        model.statusToasts = toasts
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "tmux")
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxCluster)
        try await bind(Self.main, on: model, for: sessionID, using: adapter)

        model.hop(tabToward: .forward)
        try await waitUntil { !model.isHoppingMuxSession }

        #expect(
            await adapter.focusLog.targets == [MuxTarget(session: Self.main, group: Self.window2)]
        )
        #expect(await adapter.switchLog.switches.isEmpty)
        #expect(toasts.items.first?.title == "Switched to tests")
        #expect(model.swipeTarget(.forward) == .muxGroup(Self.window3))
    }

    @Test func aHerdrTabHopFocusesTheTabTheSessionSwitchWouldRefuse() async throws {
        let model = SessionWorkspaceFixture.model()
        let toasts = StatusToastCenter()
        model.statusToasts = toasts
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "herdr")
        let adapter = FixtureMultiplexerAdapter(fixture: .herdrCluster)
        try await bind(Self.herdrDefault, on: model, for: sessionID, using: adapter)

        #expect(model.swipeTarget(.forward) == .muxGroup(Self.herdrWeb))

        model.hop(tabToward: .forward)
        try await waitUntil { !model.isHoppingMuxSession }

        #expect(
            await adapter.focusLog.targets == [
                MuxTarget(session: Self.herdrDefault, group: Self.herdrWeb)
            ]
        )
        #expect(toasts.items.map(\.severity) == [.success])
        #expect(toasts.items.first?.title == "Switched to web")
    }

    @Test func anUnreadableTerminalSkipsTheTabAndFallsBackToTheAppSegment() async throws {
        let model = SessionWorkspaceFixture.model()
        let toasts = StatusToastCenter()
        model.statusToasts = toasts
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "tmux")
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxCluster)
        try await bind(Self.main, on: model, for: sessionID, using: adapter)
        model.connections[sessionID] = MockRemoteConnection()

        #expect(model.swipeTarget(.forward) == .muxGroup(Self.window2))

        let skips = SkipRecorder()
        model.hop(tabToward: .forward) { skips.record() }
        try await waitUntil { !model.isHoppingMuxSession }

        #expect(skips.count == 1)
        #expect(model.sessionMuxGroupIDs[sessionID] == nil)
        #expect(await adapter.focusLog.targets.isEmpty)
        #expect(toasts.items.map(\.severity) == [.attention])
        #expect(model.swipeTarget(.forward, skippingMux: true) == .appSession(model.registry.ids[1]))
    }

    @Test func aTabChangedBehindTheAppsBackAnchorsTheNextSwipe() async throws {
        let model = SessionWorkspaceFixture.model()
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "tmux")
        let adapter = SwipeRingMuxAdapter(names: ["alpha"], groupTitles: ["code", "tests", "logs"])
        try await bind(Self.alpha, on: model, for: sessionID, using: adapter)
        #expect(model.swipeTarget(.forward) == .muxGroup(Self.alphaTests))

        try await adapter.focus(MuxTarget(session: Self.alpha, group: Self.alphaTests))
        model.hop(tabToward: .forward)
        try await waitUntil { !model.isHoppingMuxSession }

        #expect(
            await adapter.focusLog.targets.last == MuxTarget(session: Self.alpha, group: Self.alphaLogs)
        )
        #expect(model.sessionMuxGroupIDs[sessionID] == Self.alphaLogs)
    }

    private func bind(
        _ muxSessionID: MuxSessionID,
        on model: SessionWorkspaceModel,
        for sessionID: SessionID,
        using adapter: any MultiplexerAdapter
    ) async throws {
        model.replaceMultiplexer(for: sessionID, with: adapter)
        try await waitUntil { !model.muxTopologyCache.sessions(for: sessionID).isEmpty }
        model.rememberMuxSession(muxSessionID, for: sessionID)
        await model.refreshMuxTopology(for: sessionID, using: adapter)
    }

    private static let alpha = MuxSessionID(rawValue: "alpha")
    private static let alphaCode = MuxGroupID(rawValue: "alpha:code")
    private static let alphaTests = MuxGroupID(rawValue: "alpha:tests")
    private static let alphaLogs = MuxGroupID(rawValue: "alpha:logs")
    private static let main = MuxSessionID(rawValue: "$1")
    private static let window2 = MuxGroupID(rawValue: "@2")
    private static let window3 = MuxGroupID(rawValue: "@3")
    private static let herdrDefault = MuxSessionID(rawValue: "default")
    private static let herdrWeb = MuxGroupID(rawValue: "w1:t2")
}
