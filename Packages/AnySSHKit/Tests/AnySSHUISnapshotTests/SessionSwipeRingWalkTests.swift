import AnySSHCore
import AnySSHMocks
import Sessions
import Testing

@testable import AnySSHUI

@Suite @MainActor struct SessionSwipeRingWalkTests {
    @Test func aForwardWalkVisitsEveryMuxSessionThenTheNextAppSession() async throws {
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
                .appSession(model.registry.ids[1]),
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
        #expect(model.swipeTarget(.forward) == .appSession(model.registry.ids[1]))
        #expect(model.swipeTarget(.backward) == .appSession(model.registry.ids[3]))
    }

    private func walk(
        _ direction: SessionSwipeRing.Direction,
        steps: Int,
        on model: SessionWorkspaceModel
    ) async throws -> [SessionSwipeRing.Target] {
        var visited = [SessionSwipeRing.Target]()
        for _ in 0..<steps {
            guard let target = model.swipeTarget(direction) else { break }
            visited.append(target)
            guard case .muxSession(let muxSessionID) = target else { break }
            model.hop(toMuxSession: muxSessionID)
            try await waitUntil { !model.isHoppingMuxSession }
        }
        return visited
    }

    private func install(
        _ adapter: FixtureMultiplexerAdapter,
        on model: SessionWorkspaceModel,
        for sessionID: SessionID
    ) async throws {
        model.replaceMultiplexer(for: sessionID, with: adapter)
        try await waitUntil { model.muxSessionCache.sessions(for: sessionID).count > 1 }
    }

    private static let main = MuxSessionID(rawValue: "$1")
    private static let api = MuxSessionID(rawValue: "$2")
    private static let infra = MuxSessionID(rawValue: "$3")
    private static let vanished = MuxSessionID(rawValue: "$9")
    private static let herdrDefault = MuxSessionID(rawValue: "default")
    private static let ops = MuxSessionID(rawValue: "ops")
}

@MainActor private final class SkipRecorder {
    private(set) var count = 0

    func record() {
        count += 1
    }
}
