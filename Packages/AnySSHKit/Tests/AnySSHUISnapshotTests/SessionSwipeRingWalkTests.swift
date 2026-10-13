import AnySSHCore
import AnySSHMocks
import Sessions
import Testing

@testable import AnySSHUI

@Suite @MainActor struct SessionSwipeRingWalkTests {
    @Test func aForwardWalkVisitsEveryMuxSessionThenTheTabsOfTheLastOne() async throws {
        let model = SessionWorkspaceFixture.model()
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "tmux")
        let adapter = FixtureMultiplexerAdapter(fixture: .tmuxCluster)
        try await install(adapter, on: model, for: sessionID)

        let visited = try await walk(.forward, steps: 4, on: model)

        #expect(
            visited == [
                .muxSession(Self.api),
                .muxSession(Self.infra),
                .muxSession(Self.main),
                .muxGroup(Self.tests),
            ]
        )
        #expect(model.sessionMuxIDs[sessionID] == Self.main)
        #expect(
            await adapter.switchLog.switches == [
                MuxSessionSwitch(target: Self.api, source: Self.main),
                MuxSessionSwitch(target: Self.infra, source: Self.api),
                MuxSessionSwitch(target: Self.main, source: Self.infra),
            ]
        )
    }

    @Test func aBackwardWalkVisitsEveryMuxSessionAndWrapsOnALoneAppSession() async throws {
        let model = SessionWorkspaceFixture.model("single")
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "tmux")
        try await install(
            FixtureMultiplexerAdapter(fixture: .tmuxCluster),
            on: model,
            for: sessionID
        )

        let visited = try await walk(.backward, steps: 4, on: model)

        #expect(
            visited == [
                .muxSession(Self.main),
                .muxSession(Self.infra),
                .muxSession(Self.api),
                .muxSession(Self.main),
            ]
        )
    }

    @Test func aBindingMissingFromTheListReentersTheRingAsUnbound() async throws {
        let model = SessionWorkspaceFixture.model()
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "tmux")
        try await install(
            FixtureMultiplexerAdapter(fixture: .tmuxCluster),
            on: model,
            for: sessionID
        )
        model.rememberMuxSession(Self.vanished, for: sessionID)

        #expect(model.swipeTarget(.forward) == .muxSession(Self.api))
        #expect(model.swipeTarget(.backward) == .appSession(model.registry.ids[3]))

        model.hop(toMuxSession: Self.api)
        try await waitUntil { !model.isHoppingMuxSession }

        #expect(model.sessionMuxIDs[sessionID] == Self.api)
    }

    @Test func aRefusedHerdrHopDropsTheMuxSegmentAndKeepsWalking() async throws {
        let model = SessionWorkspaceFixture.model()
        let toasts = StatusToastCenter()
        model.statusToasts = toasts
        let sessionID = try #require(model.activeSessionID)
        model.connections[sessionID] = SessionWorkspaceFixture.attachedConnection(running: "herdr")
        let adapter = FixtureMultiplexerAdapter(fixture: .herdrCluster)
        try await install(adapter, on: model, for: sessionID)
        model.rememberMuxSession(Self.herdrDefault, for: sessionID)

        #expect(model.swipeTarget(.forward) == .muxSession(Self.ops))

        let skips = SkipRecorder()
        model.hop(toMuxSession: Self.ops) { skips.record() }
        try await waitUntil { !model.isHoppingMuxSession }

        #expect(skips.count == 1)
        #expect(model.sessionMuxIDs[sessionID] == Self.herdrDefault)
        #expect(await adapter.switchLog.switches.isEmpty)
        #expect(toasts.items.map(\.severity) == [.attention])
        #expect(model.swipeTarget(.forward, skippingMux: true) == .appSession(model.registry.ids[1]))
        #expect(
            model.swipeTarget(.backward, skippingMux: true) == .appSession(model.registry.ids[3])
        )

        try await settle(model, for: sessionID)

        #expect(model.swipeTarget(.forward) == .muxGroup(Self.herdrWeb))
    }

    private func walk(
        _ direction: SessionSwipeRing.Direction,
        steps: Int,
        on model: SessionWorkspaceModel
    ) async throws -> [SessionSwipeRing.Target] {
        guard let sessionID = model.activeSessionID else { return [] }
        var visited = [SessionSwipeRing.Target]()
        for _ in 0..<steps {
            guard let target = model.swipeTarget(direction) else { break }
            visited.append(target)
            switch target {
            case .muxGroup: model.hop(tabToward: direction)
            case .muxSession(let muxSessionID): model.hop(toMuxSession: muxSessionID)
            case .appSession: return visited
            }
            try await settle(model, for: sessionID)
        }
        return visited
    }

    private func settle(_ model: SessionWorkspaceModel, for sessionID: SessionID) async throws {
        try await waitUntil { !model.isHoppingMuxSession }
        guard let bound = model.sessionMuxIDs[sessionID] else { return }
        try await waitUntil {
            model.muxTopologyCache.groups(for: sessionID).first?.sessionID == bound
        }
    }

    private func install(
        _ adapter: FixtureMultiplexerAdapter,
        on model: SessionWorkspaceModel,
        for sessionID: SessionID
    ) async throws {
        model.replaceMultiplexer(for: sessionID, with: adapter)
        try await waitUntil { model.muxTopologyCache.sessions(for: sessionID).count > 1 }
    }

    private static let main = MuxSessionID(rawValue: "$1")
    private static let api = MuxSessionID(rawValue: "$2")
    private static let infra = MuxSessionID(rawValue: "$3")
    private static let tests = MuxGroupID(rawValue: "@2")
    private static let vanished = MuxSessionID(rawValue: "$9")
    private static let herdrDefault = MuxSessionID(rawValue: "default")
    private static let ops = MuxSessionID(rawValue: "ops")
    private static let herdrWeb = MuxGroupID(rawValue: "w1:t2")
}
