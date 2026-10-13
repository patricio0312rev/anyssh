import AnySSHCore
import AnySSHMocks
import Sessions
import Testing

@testable import AnySSHUI

@Suite @MainActor struct SessionMuxTopologyFreshnessTests {
    @Test func activatingASessionRefreshesItsTopology() async throws {
        let model = SessionWorkspaceFixture.model()
        let target = model.registry.ids[1]
        model.sessionAdapters[target] = SwipeRingMuxAdapter(names: ["alpha", "beta"])

        model.activate(target)

        try await waitUntil { !model.muxTopologyCache.sessions(for: target).isEmpty }
        #expect(model.muxTopologyCache.sessions(for: target).map(\.name) == ["alpha", "beta"])
    }

    @Test func aRefreshLandingAfterACloseNeverRefillsTheCache() async throws {
        let model = SessionWorkspaceFixture.model()
        let closed = model.registry.ids[1]
        let adapter = SwipeRingMuxAdapter(names: ["alpha", "beta"])

        await model.close(closed)
        await model.refreshMuxTopology(for: closed, using: adapter)

        #expect(model.muxTopologyCache.sessions(for: closed).isEmpty)
    }

    @Test func aRefreshForAnOpenSessionStillLands() async throws {
        let model = SessionWorkspaceFixture.model()
        let open = model.registry.ids[1]

        await model.refreshMuxTopology(for: open, using: SwipeRingMuxAdapter(names: ["alpha"]))

        #expect(model.muxTopologyCache.sessions(for: open).map(\.name) == ["alpha"])
    }
}
