import AnySSHCore
import Testing

@testable import AnySSHUI

@MainActor
struct SessionMuxTopologyCacheTests {
    private static let session = SessionID(rawValue: "session-1")
    private static let main = MuxSession(
        id: MuxSessionID(rawValue: "$1"),
        name: "main",
        isAttached: true
    )
    private static let code = MuxGroup(
        id: MuxGroupID(rawValue: "@1"),
        sessionID: main.id,
        title: "code",
        isActive: true
    )

    @Test func aStoreFromTheCurrentGenerationLandsSessionsAndGroupsTogether() {
        let cache = SessionMuxTopologyCache()
        let generation = cache.generation(for: Self.session)

        cache.store(topology(), for: Self.session, generation: generation)

        #expect(cache.sessions(for: Self.session) == [Self.main])
        #expect(cache.groups(for: Self.session) == [Self.code])
    }

    @Test func aStaleTopologyAfterAClearIsDropped() {
        let cache = SessionMuxTopologyCache()
        let generation = cache.generation(for: Self.session)
        cache.clear(for: Self.session)

        cache.store(topology(), for: Self.session, generation: generation)

        #expect(cache.sessions(for: Self.session).isEmpty)
        #expect(cache.groups(for: Self.session).isEmpty)
    }

    @Test func aClearOnlyInvalidatesItsOwnSession() {
        let cache = SessionMuxTopologyCache()
        let other = SessionID(rawValue: "session-2")
        cache.clear(for: Self.session)

        cache.store(topology(), for: other, generation: cache.generation(for: other))

        #expect(cache.sessions(for: other) == [Self.main])
    }

    @Test func groupsStayKeyedToTheMuxSessionThatProducedThem() {
        let cache = SessionMuxTopologyCache()

        cache.store(topology(), for: Self.session, generation: cache.generation(for: Self.session))

        #expect(cache.groups(for: Self.session).map(\.sessionID) == [Self.main.id])
    }

    @Test func aReplacingStoreNeverMixesOldGroupsWithNewSessions() {
        let cache = SessionMuxTopologyCache()
        cache.store(topology(), for: Self.session, generation: cache.generation(for: Self.session))
        let api = MuxSession(id: MuxSessionID(rawValue: "$2"), name: "api", isAttached: false)

        cache.store(
            SessionMuxTopologyCache.Topology(sessions: [api], groups: []),
            for: Self.session,
            generation: cache.generation(for: Self.session)
        )

        #expect(cache.sessions(for: Self.session) == [api])
        #expect(cache.groups(for: Self.session).isEmpty)
    }

    private func topology() -> SessionMuxTopologyCache.Topology {
        SessionMuxTopologyCache.Topology(sessions: [Self.main], groups: [Self.code])
    }
}
