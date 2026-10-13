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
        model.hop(toMuxSession: Self.beta, within: Self.shortBudget) { skips.record() }
        try await waitInRealTime { !model.isHoppingMuxSession }

        #expect(skips.count == 1)
        #expect(model.sessionMuxIDs[sessionID] == Self.alpha)
        #expect(toasts.items.first?.title == MuxNavigationCopy.skipped(.timedOut).title)

        model.hop(toMuxSession: Self.beta, within: Self.shortBudget) { skips.record() }
        #expect(model.isHoppingMuxSession)
        await gate.open()
        try await waitInRealTime { !model.isHoppingMuxSession }
    }

    @Test func aSwipeIsFreedOnlyOnceThePostHopTopologyLanded() async throws {
        let model = SessionWorkspaceFixture.model("single")
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "tmux")
        let adapter = SwipeRingMuxAdapter(names: ["alpha", "beta"])
        try await install(adapter, on: model, for: sessionID)
        model.rememberMuxSession(Self.alpha, for: sessionID)
        await model.refreshMuxTopology(for: sessionID, using: adapter)
        #expect(model.muxTopologyCache.groups(for: sessionID).first?.sessionID == Self.alpha)

        model.hop(toMuxSession: Self.beta)
        try await waitUntil { !model.isHoppingMuxSession }

        #expect(model.muxTopologyCache.groups(for: sessionID).first?.sessionID == Self.beta)
    }

    @Test func aHungPostHopRefreshStillFreesTheSwipe() async throws {
        let model = SessionWorkspaceFixture.model("single")
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "tmux")
        let gate = MuxHopGate()
        let adapter = SwipeRingMuxAdapter(names: ["alpha", "beta"], snapshotGate: gate)
        try await install(adapter, on: model, for: sessionID)
        model.rememberMuxSession(Self.alpha, for: sessionID)

        model.hop(toMuxSession: Self.beta, within: Self.postHopBudget)
        try await waitInRealTime { !model.isHoppingMuxSession }

        #expect(model.sessionMuxIDs[sessionID] == Self.beta)
        await gate.open()
    }

    @Test func aSwitchLandingAfterTheDeadlineIsRememberedInsteadOfSkipped() async throws {
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
        model.hop(toMuxSession: Self.beta, within: Self.drainingBudget) { skips.record() }
        try await Task.sleep(for: Self.pastTheLimit)

        #expect(model.isHoppingMuxSession)
        #expect(skips.count == 0)

        await gate.open()
        try await waitInRealTime { !model.isHoppingMuxSession }

        #expect(skips.count == 0)
        #expect(model.sessionMuxIDs[sessionID] == Self.beta)
        #expect(toasts.items.map(\.title) == ["Switched to beta"])
    }

    @Test func aHungTabRefreshStillFreesTheSwipe() async throws {
        let model = SessionWorkspaceFixture.model("single")
        let toasts = StatusToastCenter()
        model.statusToasts = toasts
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "tmux")
        let adapter = SwipeRingMuxAdapter(names: ["alpha"], groupTitles: ["code", "tests"])
        try await install(adapter, on: model, for: sessionID)
        model.rememberMuxSession(Self.alpha, for: sessionID)
        await model.refreshMuxTopology(for: sessionID, using: adapter)
        #expect(model.swipeTarget(.forward) == .muxGroup(MuxGroupID(rawValue: "alpha:tests")))
        let gate = MuxHopGate()
        let hung = SwipeRingMuxAdapter(names: ["alpha"], groupTitles: ["code", "tests"], snapshotGate: gate)
        model.sessionAdapters[sessionID] = hung

        let skips = SkipRecorder()
        model.hop(tabToward: .forward, within: Self.shortBudget) { skips.record() }
        try await waitInRealTime { !model.isHoppingMuxSession }

        #expect(skips.count == 1)
        #expect(await hung.focusLog.targets.isEmpty)
        #expect(toasts.items.first?.title == MuxNavigationCopy.skipped(.timedOut).title)
        await gate.open()
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

    nonisolated static let plainReasons: [MuxSkipReason] = [
        .detached, .unidentified, .unreadable, .boundElsewhere, .timedOut,
    ]
    private static let alpha = MuxSessionID(rawValue: "alpha")
    private static let beta = MuxSessionID(rawValue: "beta")
    private static let shortBudget = MuxHopBudget(limit: .milliseconds(50), grace: .milliseconds(50))
    private static let postHopBudget = MuxHopBudget(limit: .seconds(1), grace: .milliseconds(50))
    private static let drainingBudget = MuxHopBudget(limit: .seconds(1), grace: .seconds(5))
    private static let pastTheLimit = Duration.milliseconds(1500)
    private static let realTimeStep = Duration.milliseconds(10)
    private static let realTimeAttempts = 800
}
