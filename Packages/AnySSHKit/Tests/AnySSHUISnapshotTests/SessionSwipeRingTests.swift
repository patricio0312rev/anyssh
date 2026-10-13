import AnySSHCore
import Testing

@testable import AnySSHUI

@Suite struct SessionSwipeRingTests {
    @Test func forwardLeavesAMuxSessionForTheNextOne() {
        let ring = makeRing(mux: ["alpha", "beta"], bound: "alpha", apps: ["a", "b"], active: "a")

        #expect(ring.step(.forward) == muxTarget("beta"))
    }

    @Test func forwardEntersTheAppSegmentOnceTheMuxSessionsRunOut() {
        let ring = makeRing(mux: ["alpha", "beta"], bound: "beta", apps: ["a", "b", "c"], active: "a")

        #expect(ring.step(.forward) == appTarget("b"))
    }

    @Test func forwardWrapsFromTheLastMuxSessionWhenNoOtherAppSessionExists() {
        let ring = makeRing(mux: ["alpha", "beta"], bound: "beta", apps: ["a"], active: "a")

        #expect(ring.step(.forward) == muxTarget("alpha"))
    }

    @Test func backwardLeavesAMuxSessionForThePreviousOne() {
        let ring = makeRing(mux: ["alpha", "beta"], bound: "beta", apps: ["a", "b"], active: "a")

        #expect(ring.step(.backward) == muxTarget("alpha"))
    }

    @Test func backwardWrapsFromTheFirstMuxSessionIntoTheLastAppSession() {
        let ring = makeRing(mux: ["alpha", "beta"], bound: "alpha", apps: ["a", "b", "c"], active: "a")

        #expect(ring.step(.backward) == appTarget("c"))
    }

    @Test func backwardWrapsToTheLastMuxSessionWhenNoOtherAppSessionExists() {
        let ring = makeRing(mux: ["alpha", "beta"], bound: "alpha", apps: ["a"], active: "a")

        #expect(ring.step(.backward) == muxTarget("beta"))
    }

    @Test func theAppSegmentFollowsTheActiveSessionInRegistryOrder() {
        let ring = makeRing(mux: ["alpha"], bound: "alpha", apps: ["a", "b", "c"], active: "b")

        #expect(ring.step(.forward) == appTarget("c"))
        #expect(ring.step(.backward) == appTarget("a"))
    }

    @Test func anUnboundRingEntersTheMuxSegmentGoingForward() {
        let ring = makeRing(mux: ["alpha", "beta"], bound: nil, apps: ["a", "b"], active: "a")

        #expect(ring.step(.forward) == muxTarget("alpha"))
    }

    @Test func anUnboundRingEntersThePreviousAppSessionGoingBackward() {
        let ring = makeRing(mux: ["alpha", "beta"], bound: nil, apps: ["a", "b", "c"], active: "a")

        #expect(ring.step(.backward) == appTarget("c"))
    }

    @Test func anUnboundRingWithoutOtherAppSessionsEntersTheLastMuxSession() {
        let ring = makeRing(mux: ["alpha", "beta"], bound: nil, apps: ["a"], active: "a")

        #expect(ring.step(.backward) == muxTarget("beta"))
    }

    @Test func aBindingThatVanishedBehavesLikeNoBinding() {
        let ring = makeRing(mux: ["alpha", "beta"], bound: "gone", apps: ["a", "b"], active: "a")

        #expect(ring.step(.forward) == muxTarget("alpha"))
        #expect(ring.step(.backward) == appTarget("b"))
    }

    @Test func rawListOrderIsSortedByName() {
        let ring = makeRing(mux: ["work", "alpha", "notes"], bound: nil, apps: ["a"], active: "a")

        #expect(ring.step(.forward) == muxTarget("alpha"))
        #expect(ring.step(.backward) == muxTarget("work"))
    }

    @Test func duplicateNamesAreOrderedByIdentifier() {
        let sessions = [
            MuxSession(id: MuxSessionID(rawValue: "$3"), name: "work", isAttached: false),
            MuxSession(id: MuxSessionID(rawValue: "$1"), name: "work", isAttached: true),
            MuxSession(id: MuxSessionID(rawValue: "$2"), name: "work", isAttached: false),
        ]
        let ring = SessionSwipeRing(
            muxSessions: sessions,
            boundMuxSession: MuxSessionID(rawValue: "$1"),
            appSessionIDs: [SessionID(rawValue: "a")],
            activeSessionID: SessionID(rawValue: "a")
        )

        #expect(ring.step(.forward) == muxTarget("$2"))
        #expect(ring.step(.backward) == muxTarget("$3"))
    }

    @Test func aHostWithoutMuxSessionsWalksTheAppSessionsAlone() {
        let ring = makeRing(mux: [], bound: nil, apps: ["a", "b", "c"], active: "b")

        #expect(ring.step(.forward) == appTarget("c"))
        #expect(ring.step(.backward) == appTarget("a"))
    }

    @Test func aLoneAppSessionWithoutMuxSessionsHasNowhereToGo() {
        let ring = makeRing(mux: [], bound: nil, apps: ["a"], active: "a")

        #expect(ring.step(.forward) == nil)
        #expect(ring.step(.backward) == nil)
    }

    @Test func aLoneMuxSessionAlreadyBoundHasNowhereToGo() {
        let ring = makeRing(mux: ["alpha"], bound: "alpha", apps: ["a"], active: "a")

        #expect(ring.step(.forward) == nil)
        #expect(ring.step(.backward) == nil)
    }

    @Test func aLoneMuxSessionIsStillReachableFromTheSeam() {
        let ring = makeRing(mux: ["alpha"], bound: nil, apps: ["a"], active: "a")

        #expect(ring.step(.forward) == muxTarget("alpha"))
        #expect(ring.step(.backward) == muxTarget("alpha"))
    }

    private func makeRing(
        mux names: [String],
        bound: String?,
        apps: [String],
        active: String
    ) -> SessionSwipeRing {
        SessionSwipeRing(
            muxSessions: names.map {
                MuxSession(id: MuxSessionID(rawValue: $0), name: $0, isAttached: false)
            },
            boundMuxSession: bound.map { MuxSessionID(rawValue: $0) },
            appSessionIDs: apps.map { SessionID(rawValue: $0) },
            activeSessionID: SessionID(rawValue: active)
        )
    }

    private func muxTarget(_ id: String) -> SessionSwipeRing.Target {
        .muxSession(MuxSessionID(rawValue: id))
    }

    private func appTarget(_ id: String) -> SessionSwipeRing.Target {
        .appSession(SessionID(rawValue: id))
    }
}
