import AnySSHCore
import AnySSHMocks
import Sessions
import Testing

@testable import AnySSHUI

@Suite @MainActor struct SessionSwipeHopSafetyTests {
    @Test func aSwipeOnATerminalOutsideTheMultiplexerTypesNothingAndFallsBack() async throws {
        let model = SessionWorkspaceFixture.model("single")
        let toasts = StatusToastCenter()
        model.statusToasts = toasts
        let sessionID = try #require(model.activeSessionID)
        let connection = SessionWorkspaceFixture.attachedConnection(running: "vim")
        model.connections[sessionID] = connection
        let adapter = SwipeRingMuxAdapter(names: ["alpha", "beta"])
        try await install(adapter, on: model, for: sessionID)

        let skips = SkipRecorder()
        model.hop(toMuxSession: Self.alpha) { skips.record() }
        try await waitUntil { !model.isHoppingMuxSession }

        #expect(skips.count == 1)
        #expect(await connection.displayWrites.isEmpty)
        #expect(await adapter.switchLog.switches.isEmpty)
        #expect(model.sessionMuxIDs[sessionID] == nil)
        #expect(toasts.items.first?.title == MuxNavigationCopy.skipped(.detached).title)
    }

    @Test func aHungHopTimesOutFallsBackAndFreesTheNextSwipe() async throws {
        let model = SessionWorkspaceFixture.model("single")
        let toasts = StatusToastCenter()
        model.statusToasts = toasts
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "tmux")
        let gate = MuxHopGate()
        let adapter = SwipeRingMuxAdapter(names: ["alpha", "beta"], switchGate: gate)
        try await install(adapter, on: model, for: sessionID)
        model.rememberMuxSession(Self.alpha, for: sessionID)

        let skips = SkipRecorder()
        model.hop(toMuxSession: Self.beta, within: Self.shortLimit) { skips.record() }
        try await waitInRealTime { !model.isHoppingMuxSession }

        #expect(skips.count == 1)
        #expect(model.sessionMuxIDs[sessionID] == Self.alpha)
        #expect(toasts.items.first?.title == MuxNavigationCopy.skipped(.timedOut).title)

        model.hop(toMuxSession: Self.beta, within: Self.shortLimit) { skips.record() }
        #expect(model.isHoppingMuxSession)
        await gate.open()
        try await waitInRealTime { !model.isHoppingMuxSession }
    }

    @Test(
        arguments: [
            CancellationError(),
            ErrorState.transport(.cancelledBySwitch),
            ErrorState.mux(.absent),
        ] as [any Error])
    func aFailedRefreshKeepsTheLastGoodTopology(failure: any Error) async throws {
        let model = SessionWorkspaceFixture.model("single")
        let sessionID = try #require(model.activeSessionID)
        try await install(SwipeRingMuxAdapter(names: ["alpha", "beta"]), on: model, for: sessionID)
        let before = model.muxTopologyCache.topology(for: sessionID)

        await model.refreshMuxTopology(
            for: sessionID,
            using: SwipeRingMuxAdapter(names: [], listFailure: failure)
        )

        #expect(model.muxTopologyCache.topology(for: sessionID) == before)
        #expect(model.swipeTarget(.forward) == .muxSession(Self.alpha))
    }

    @Test(arguments: Self.plainReasons)
    func eachSkipReasonHasItsOwnCopy(reason: MuxSkipReason) {
        let copy = MuxNavigationCopy.skipped(reason)

        #expect(!copy.title.isEmpty)
        #expect(!copy.body.isEmpty)
        for other in Self.plainReasons where other != reason {
            #expect(MuxNavigationCopy.skipped(other).title != copy.title)
        }
    }

    @Test(arguments: [MuxErrorState.sessionSwitchUnsupported, .attachTargetVanished])
    func aRefusalShowsItsErrorStateCopy(state: MuxErrorState) {
        let copy = MuxNavigationCopy.skipped(.refused(.mux(state)))

        #expect(copy.title == state.copy.title)
        #expect(copy.body == state.copy.body)
    }

    private func install(
        _ adapter: SwipeRingMuxAdapter,
        on model: SessionWorkspaceModel,
        for sessionID: SessionID
    ) async throws {
        model.replaceMultiplexer(for: sessionID, with: adapter)
        try await waitUntil { !model.muxTopologyCache.sessions(for: sessionID).isEmpty }
    }

    private func waitInRealTime(_ condition: () -> Bool) async throws {
        for _ in 0..<Self.realTimeAttempts {
            if condition() { return }
            try await Task.sleep(for: Self.realTimeStep)
        }
        throw GatedDisplayWriter.Failure.neverSatisfied
    }

    static let plainReasons: [MuxSkipReason] = [
        .detached, .unidentified, .unreadable, .boundElsewhere, .timedOut,
    ]
    private static let alpha = MuxSessionID(rawValue: "alpha")
    private static let beta = MuxSessionID(rawValue: "beta")
    private static let shortLimit = Duration.milliseconds(50)
    private static let realTimeStep = Duration.milliseconds(10)
    private static let realTimeAttempts = 300
}
