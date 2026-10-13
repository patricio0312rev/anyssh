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

    @Test func aStoreFromTheLatestRequestLandsSessionsAndGroupsTogether() {
        let cache = SessionMuxTopologyCache()
        let request = cache.beginRefresh(for: Self.session)

        cache.store(topology(), for: Self.session, request: request)

        #expect(cache.sessions(for: Self.session) == [Self.main])
        #expect(cache.groups(for: Self.session) == [Self.code])
    }

    @Test func aStaleTopologyAfterAClearIsDropped() {
        let cache = SessionMuxTopologyCache()
        let request = cache.beginRefresh(for: Self.session)
        cache.clear(for: Self.session)

        cache.store(topology(), for: Self.session, request: request)

        #expect(cache.sessions(for: Self.session).isEmpty)
        #expect(cache.groups(for: Self.session).isEmpty)
    }

    @Test func aClearOnlyInvalidatesItsOwnSession() {
        let cache = SessionMuxTopologyCache()
        let other = SessionID(rawValue: "session-2")
        cache.clear(for: Self.session)

        cache.store(topology(), for: other, request: cache.beginRefresh(for: other))

        #expect(cache.sessions(for: other) == [Self.main])
    }

    @Test func groupsStayKeyedToTheMuxSessionThatProducedThem() {
        let cache = SessionMuxTopologyCache()

        cache.store(topology(), for: Self.session, request: cache.beginRefresh(for: Self.session))

        #expect(cache.groups(for: Self.session).map(\.sessionID) == [Self.main.id])
    }

    @Test func aReplacingStoreNeverMixesOldGroupsWithNewSessions() {
        let cache = SessionMuxTopologyCache()
        cache.store(topology(), for: Self.session, request: cache.beginRefresh(for: Self.session))
        let api = MuxSession(id: MuxSessionID(rawValue: "$2"), name: "api", isAttached: false)

        cache.store(
            SessionMuxTopologyCache.Topology(sessions: [api], groups: []),
            for: Self.session,
            request: cache.beginRefresh(for: Self.session)
        )

        #expect(cache.sessions(for: Self.session) == [api])
        #expect(cache.groups(for: Self.session).isEmpty)
    }

    @Test func anOlderRefreshFinishingLastNeverOverwritesTheNewerOne() {
        let cache = SessionMuxTopologyCache()
        let api = MuxSession(id: MuxSessionID(rawValue: "$2"), name: "api", isAttached: true)
        let newer = SessionMuxTopologyCache.Topology(sessions: [api], groups: [])
        let olderRequest = cache.beginRefresh(for: Self.session)
        let newerRequest = cache.beginRefresh(for: Self.session)

        cache.store(newer, for: Self.session, request: newerRequest)
        cache.store(topology(), for: Self.session, request: olderRequest)

        #expect(cache.topology(for: Self.session) == newer)
    }

    @Test func aRequestFromAnotherSessionNeverInvalidatesThisOne() {
        let cache = SessionMuxTopologyCache()
        let request = cache.beginRefresh(for: Self.session)
        _ = cache.beginRefresh(for: SessionID(rawValue: "session-2"))

        cache.store(topology(), for: Self.session, request: request)

        #expect(cache.sessions(for: Self.session) == [Self.main])
    }

    @Test func markingAGroupActiveClearsTheOthers() {
        let cache = SessionMuxTopologyCache()
        let tests = MuxGroup(
            id: MuxGroupID(rawValue: "@2"), sessionID: Self.main.id, title: "tests", isActive: false)
        cache.store(
            SessionMuxTopologyCache.Topology(sessions: [Self.main], groups: [Self.code, tests]),
            for: Self.session,
            request: cache.beginRefresh(for: Self.session)
        )

        cache.markActive(tests.id, for: Self.session)

        #expect(cache.groups(for: Self.session).filter(\.isActive).map(\.id) == [tests.id])
        #expect(cache.groups(for: Self.session).map(\.id) == [Self.code.id, tests.id])
    }

    @Test func markingAnUnknownGroupLeavesTheTopologyAlone() {
        let cache = SessionMuxTopologyCache()
        cache.store(topology(), for: Self.session, request: cache.beginRefresh(for: Self.session))

        cache.markActive(MuxGroupID(rawValue: "@9"), for: Self.session)

        #expect(cache.topology(for: Self.session) == topology())
    }

    @Test func aRefreshStartedBeforeAMarkNeverUndoesIt() {
        let cache = SessionMuxTopologyCache()
        let tests = MuxGroup(
            id: MuxGroupID(rawValue: "@2"), sessionID: Self.main.id, title: "tests", isActive: false)
        let before = SessionMuxTopologyCache.Topology(sessions: [Self.main], groups: [Self.code, tests])
        cache.store(before, for: Self.session, request: cache.beginRefresh(for: Self.session))
        let inFlight = cache.beginRefresh(for: Self.session)

        cache.markActive(tests.id, for: Self.session)
        cache.store(before, for: Self.session, request: inFlight)

        #expect(cache.groups(for: Self.session).filter(\.isActive).map(\.id) == [tests.id])
    }

    private func topology() -> SessionMuxTopologyCache.Topology {
        SessionMuxTopologyCache.Topology(sessions: [Self.main], groups: [Self.code])
    }
}
