import AnySSHCore
import Testing

@testable import AnySSHUI

@Suite struct SessionSwipeRingGroupTests {
    @Test func forwardWalksTheTabsOfTheBoundSessionFirst() {
        let ring = makeRing(tabs: [("code", true), ("tests", false), ("logs", false)])

        #expect(ring.step(.forward) == groupTarget("tests"))
    }

    @Test func forwardCrossesFromTheLastTabIntoTheNextMuxSession() {
        let ring = makeRing(tabs: [("code", false), ("tests", false), ("logs", true)])

        #expect(ring.step(.forward) == muxTarget("api"))
    }

    @Test func backwardLeavesTheFirstTabForTheLastAppSession() {
        let ring = makeRing(tabs: [("code", true), ("tests", false)], apps: ["a", "b", "c"])

        #expect(ring.step(.backward) == appTarget("c"))
    }

    @Test func backwardWalksTheTabsInReverse() {
        let ring = makeRing(tabs: [("code", false), ("tests", true), ("logs", false)])

        #expect(ring.step(.backward) == groupTarget("code"))
    }

    @Test func aRingWithoutOtherSessionsWrapsFromTheLastTabToTheFirst() {
        let ring = makeRing(
            tabs: [("code", false), ("tests", true)],
            muxNames: ["main"],
            apps: ["a"]
        )

        #expect(ring.step(.forward) == groupTarget("code"))
    }

    @Test func aRingWithoutOtherSessionsWrapsBackwardToTheLastTab() {
        let ring = makeRing(
            tabs: [("code", true), ("tests", false)],
            muxNames: ["main"],
            apps: ["a"]
        )

        #expect(ring.step(.backward) == groupTarget("tests"))
    }

    @Test func theTabSegmentIsFollowedByTheOtherSessionsThenTheAppSessions() {
        let ring = makeRing(tabs: [("code", false), ("tests", false), ("logs", true)])
        let crossed = makeRing(
            tabs: [("code", false), ("tests", true)],
            bound: "api",
            apps: ["a", "b"]
        )

        #expect(ring.step(.forward) == muxTarget("api"))
        #expect(crossed.step(.forward) == muxTarget("main"))
    }

    @Test func aMissingActiveFlagAnchorsOnTheFirstTab() {
        let ring = makeRing(tabs: [("code", false), ("tests", false), ("logs", false)])

        #expect(ring.step(.forward) == groupTarget("tests"))
        #expect(ring.step(.backward) == appTarget("b"))
    }

    @Test func severalActiveTabsAnchorOnTheFirstOneInSnapshotOrder() {
        let ring = makeRing(tabs: [("code", false), ("tests", true), ("logs", true)])

        #expect(ring.step(.forward) == groupTarget("logs"))
        #expect(ring.step(.backward) == groupTarget("code"))
    }

    @Test func aFocusedTabOutranksTheActiveFlag() {
        let ring = makeRing(
            tabs: [("code", true), ("tests", false), ("logs", false)],
            focused: "tests"
        )

        #expect(ring.step(.forward) == groupTarget("logs"))
        #expect(ring.step(.backward) == groupTarget("code"))
    }

    @Test func aFocusedTabMissingFromTheSnapshotFallsBackToTheActiveFlag() {
        let ring = makeRing(
            tabs: [("code", false), ("tests", true), ("logs", false)],
            focused: "gone"
        )

        #expect(ring.step(.forward) == groupTarget("logs"))
    }

    @Test func aSessionWithOneTabKeepsTheSessionOnlyRing() {
        let ring = makeRing(tabs: [("code", true)])

        #expect(ring.step(.forward) == appTarget("b"))
        #expect(ring.step(.backward) == muxTarget("api"))
    }

    @Test func groupsOfAnotherMuxSessionNeverEnterTheRing() {
        let ring = SessionSwipeRing(
            muxSessions: Self.sessions(["main", "api"]),
            boundMuxSession: MuxSessionID(rawValue: "main"),
            boundGroups: [
                group("code", of: "api", isActive: true),
                group("tests", of: "api", isActive: false),
            ],
            appSessionIDs: [SessionID(rawValue: "a"), SessionID(rawValue: "b")],
            activeSessionID: SessionID(rawValue: "a")
        )

        #expect(ring.step(.forward) == appTarget("b"))
        #expect(ring.step(.backward) == muxTarget("api"))
    }

    @Test func anUnboundSessionKeepsTheSeamRulesDespiteCachedGroups() {
        let ring = SessionSwipeRing(
            muxSessions: Self.sessions(["main", "api"]),
            boundMuxSession: nil,
            boundGroups: [
                group("code", of: "main", isActive: true),
                group("tests", of: "main", isActive: false),
            ],
            appSessionIDs: [SessionID(rawValue: "a"), SessionID(rawValue: "b")],
            activeSessionID: SessionID(rawValue: "a")
        )

        #expect(ring.step(.forward) == muxTarget("api"))
        #expect(ring.step(.backward) == appTarget("b"))
    }

    private func makeRing(
        tabs: [(String, Bool)],
        muxNames: [String] = ["main", "api"],
        bound: String = "main",
        focused: String? = nil,
        apps: [String] = ["a", "b"]
    ) -> SessionSwipeRing {
        SessionSwipeRing(
            muxSessions: Self.sessions(muxNames),
            boundMuxSession: MuxSessionID(rawValue: bound),
            boundGroups: tabs.map { group($0.0, of: bound, isActive: $0.1) },
            focusedGroup: focused.map { MuxGroupID(rawValue: $0) },
            appSessionIDs: apps.map { SessionID(rawValue: $0) },
            activeSessionID: SessionID(rawValue: apps[0])
        )
    }

    private func group(_ id: String, of session: String, isActive: Bool) -> MuxGroup {
        MuxGroup(
            id: MuxGroupID(rawValue: id),
            sessionID: MuxSessionID(rawValue: session),
            title: id,
            isActive: isActive
        )
    }

    private static func sessions(_ names: [String]) -> [MuxSession] {
        names.map { MuxSession(id: MuxSessionID(rawValue: $0), name: $0, isAttached: false) }
    }

    private func groupTarget(_ id: String) -> SessionSwipeRing.Target {
        .muxGroup(MuxGroupID(rawValue: id))
    }

    private func muxTarget(_ id: String) -> SessionSwipeRing.Target {
        .muxSession(MuxSessionID(rawValue: id))
    }

    private func appTarget(_ id: String) -> SessionSwipeRing.Target {
        .appSession(SessionID(rawValue: id))
    }
}
