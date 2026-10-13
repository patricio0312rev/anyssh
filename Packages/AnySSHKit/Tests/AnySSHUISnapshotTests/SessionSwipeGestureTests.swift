import AnySSHCore
import AnySSHMocks
import Sessions
import Testing

@testable import AnySSHUI

@Suite @MainActor struct SessionSwipeGestureTests {
    @Test func aSwipeInsideTheMuxSegmentSwitchesAndRecordsTheBinding() async throws {
        let model = SessionWorkspaceFixture.model("single")
        let toasts = StatusToastCenter()
        model.statusToasts = toasts
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "tmux")
        let adapter = SwipeRingMuxAdapter(names: ["alpha", "beta"])
        try await install(adapter, on: model, for: sessionID)
        model.rememberMuxSession(Self.alpha, for: sessionID)

        #expect(model.swipeTarget(.forward) == .muxSession(Self.beta))

        model.hop(toMuxSession: Self.beta)
        try await waitUntil { !model.isHoppingMuxSession }

        #expect(model.sessionMuxIDs[sessionID] == Self.beta)
        #expect(
            await adapter.switchLog.switches == [
                MuxSessionSwitch(target: Self.beta, source: Self.alpha)
            ]
        )
        #expect(toasts.items.map(\.severity) == [.success])
        #expect(toasts.items.first?.title == "Switched to beta")
    }

    @Test func aSwipePastTheLastMuxSessionStepsToTheNextAppSession() async throws {
        let model = SessionWorkspaceFixture.model()
        let sessionID = try #require(model.activeSessionID)
        try await install(SwipeRingMuxAdapter(names: ["alpha", "beta"]), on: model, for: sessionID)
        model.rememberMuxSession(Self.beta, for: sessionID)

        #expect(model.swipeTarget(.forward) == .appSession(model.registry.ids[1]))
    }

    @Test func aRefusedHopKeepsTheBindingAndAsksForADetach() async throws {
        let model = SessionWorkspaceFixture.model("single")
        let toasts = StatusToastCenter()
        model.statusToasts = toasts
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "herdr")
        let adapter = SwipeRingMuxAdapter(
            names: ["alpha", "beta"],
            kind: .herdr,
            refusesSwitch: true
        )
        try await install(adapter, on: model, for: sessionID)

        model.hop(toMuxSession: Self.alpha)
        try await waitUntil { !model.isHoppingMuxSession }

        #expect(model.sessionMuxIDs[sessionID] == nil)
        #expect(await adapter.switchLog.switches.isEmpty)
        #expect(toasts.items.map(\.severity) == [.attention])
        #expect(toasts.items.first?.body == MuxNavigationCopy.detachToSwitch)
    }

    @Test func aSwipeDuringAHopIsDropped() async throws {
        let model = SessionWorkspaceFixture.model("single")
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "tmux")
        let adapter = SwipeRingMuxAdapter(names: ["alpha", "beta", "gamma"])
        try await install(adapter, on: model, for: sessionID)
        model.rememberMuxSession(Self.alpha, for: sessionID)

        model.hop(toMuxSession: Self.beta)
        model.hop(toMuxSession: Self.gamma)
        try await waitUntil { !model.isHoppingMuxSession }

        #expect(await adapter.switchLog.switches.map(\.target) == [Self.beta])
        #expect(model.sessionMuxIDs[sessionID] == Self.beta)
    }

    @Test func aHostWithoutMuxSessionsKeepsTheAppSessionSwipe() {
        let model = SessionWorkspaceFixture.model()

        #expect(model.swipeTarget(.forward) == .appSession(model.registry.ids[1]))
        #expect(model.swipeTarget(.backward) == .appSession(model.registry.ids[3]))
    }

    @Test func aLoneAppSessionWithoutMuxSessionsHasNowhereToSwipe() {
        let model = SessionWorkspaceFixture.model("single")

        #expect(model.swipeTarget(.forward) == nil)
        #expect(model.swipeTarget(.backward) == nil)
    }

    @Test func aLoneAppSessionStillSwipesThroughItsMuxSessions() async throws {
        let model = SessionWorkspaceFixture.model("single")
        let sessionID = try #require(model.activeSessionID)
        try await install(SwipeRingMuxAdapter(names: ["alpha", "beta"]), on: model, for: sessionID)

        #expect(model.swipeTarget(.forward) == .muxSession(Self.alpha))
        #expect(model.swipeTarget(.backward) == .muxSession(Self.beta))
    }

    private func install(
        _ adapter: SwipeRingMuxAdapter,
        on model: SessionWorkspaceModel,
        for sessionID: SessionID
    ) async throws {
        model.replaceMultiplexer(for: sessionID, with: adapter)
        try await waitUntil { !model.muxTopologyCache.sessions(for: sessionID).isEmpty }
    }

    private static let alpha = MuxSessionID(rawValue: "alpha")
    private static let beta = MuxSessionID(rawValue: "beta")
    private static let gamma = MuxSessionID(rawValue: "gamma")
}
