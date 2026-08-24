import AnySSHCore
import Testing

@testable import AnySSHUI

@MainActor
struct SessionMuxSessionCacheTests {
    private static let session = SessionID(rawValue: "session-1")
    private static let main = MuxSession(
        id: MuxSessionID(rawValue: "$1"),
        name: "main",
        isAttached: true
    )

    @Test func aStoreFromTheCurrentGenerationLands() {
        let cache = SessionMuxSessionCache()
        let generation = cache.generation(for: Self.session)

        cache.store([Self.main], for: Self.session, generation: generation)

        #expect(cache.sessions(for: Self.session) == [Self.main])
    }

    @Test func aStaleStoreAfterAClearIsDropped() {
        let cache = SessionMuxSessionCache()
        let generation = cache.generation(for: Self.session)
        cache.clear(for: Self.session)

        cache.store([Self.main], for: Self.session, generation: generation)

        #expect(cache.sessions(for: Self.session).isEmpty)
    }

    @Test func aClearOnlyInvalidatesItsOwnSession() {
        let cache = SessionMuxSessionCache()
        let other = SessionID(rawValue: "session-2")
        cache.clear(for: Self.session)

        cache.store([Self.main], for: other, generation: cache.generation(for: other))

        #expect(cache.sessions(for: other) == [Self.main])
    }
}
