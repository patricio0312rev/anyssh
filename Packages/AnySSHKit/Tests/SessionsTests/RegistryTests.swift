import AnySSHCore
import Testing

@testable import Sessions

@Suite struct SessionRegistryTests {
    @Test func openKeepsTheOrderSessionsWereOpenedIn() {
        var registry = SessionRegistry()
        registry.open(RegistryFixture.record("a"))
        registry.open(RegistryFixture.record("b"))
        registry.open(RegistryFixture.record("c"))

        #expect(registry.ids.map(\.rawValue) == ["a", "b", "c"])
        #expect(registry.count == 3)
    }

    @Test func openNumbersATitleThatIsAlreadyTaken() {
        var registry = SessionRegistry()
        registry.open(RegistryFixture.record("a", title: "build-box"))
        registry.open(RegistryFixture.record("b", title: "build-box"))
        registry.open(RegistryFixture.record("c", title: "build-box"))

        #expect(registry.titles == ["build-box", "build-box 2", "build-box 3"])
    }

    @Test func openingAnOpenSessionAgainReturnsItUntouched() {
        var registry = SessionRegistry()
        registry.open(RegistryFixture.record("a", title: "workstation"))

        let reopened = registry.open(RegistryFixture.record("a", title: "something else"))

        #expect(registry.count == 1)
        #expect(reopened.title == "workstation")
        #expect(registry[RegistryFixture.id("a")]?.title == "workstation")
    }

    @Test func renameTakesTheTitleAsTypedAndRefusesABlankOne() {
        var registry = SessionRegistry()
        registry.open(RegistryFixture.record("a", title: "one"))
        registry.open(RegistryFixture.record("b", title: "two"))

        let renamed = registry.rename(RegistryFixture.id("b"), to: "  one  ")
        #expect(renamed)
        #expect(registry.titles == ["one", "one"])
        let blankRefused = registry.rename(RegistryFixture.id("b"), to: "   ")
        #expect(!blankRefused)
        let missingRefused = registry.rename(RegistryFixture.id("missing"), to: "anything")
        #expect(!missingRefused)
        #expect(registry.titles == ["one", "one"])
    }

    @Test func aTitleFromTheHostCannotCarryControlCharacters() {
        var registry = SessionRegistry()
        registry.open(RegistryFixture.record("a", title: "one\r\nroot@prod \u{1b}[31m"))

        #expect(registry.titles == ["oneroot@prod [31m"])
    }

    @Test func closeHandsTheRecordBackSoItsSurfaceCanBeTornDown() {
        var registry = SessionRegistry()
        registry.open(RegistryFixture.record("a", connection: "conn.a"))
        registry.open(RegistryFixture.record("b", connection: "conn.b"))

        let closed = registry.close(RegistryFixture.id("a"))

        #expect(closed?.connectionID.rawValue == "conn.a")
        #expect(registry.ids.map(\.rawValue) == ["b"])
        let closedAgain = registry.close(RegistryFixture.id("a"))
        #expect(closedAgain == nil)
    }

    @Test func moveReordersAndClampsADropPastTheEnd() {
        var registry = SessionRegistry()
        for name in ["a", "b", "c"] {
            registry.open(RegistryFixture.record(name, title: name))
        }

        registry.move(RegistryFixture.id("c"), to: 0)
        #expect(registry.ids.map(\.rawValue) == ["c", "a", "b"])

        registry.move(RegistryFixture.id("c"), to: 99)
        #expect(registry.ids.map(\.rawValue) == ["a", "b", "c"])

        registry.move(RegistryFixture.id("missing"), to: 0)
        #expect(registry.ids.map(\.rawValue) == ["a", "b", "c"])
    }

    @Test func connectingResetsTheAttemptCountAndReconnectingRecordsIt() {
        var registry = SessionRegistry()
        registry.open(RegistryFixture.record("a"))
        let id = RegistryFixture.id("a")
        let later = RegistryFixture.epoch.addingTimeInterval(60)

        registry.update(id, state: .reconnecting(attempt: 3), at: later)
        #expect(registry[id]?.reconnectAttempts == 3)
        #expect(registry[id]?.lastActiveAt == RegistryFixture.epoch)

        registry.update(id, state: .connected, at: later)
        #expect(registry[id]?.reconnectAttempts == 0)
        #expect(registry[id]?.lastActiveAt == later)
    }

    @Test func theAttemptCountOutlivesAFailureAndNotAClose() {
        var registry = SessionRegistry()
        registry.open(RegistryFixture.record("a"))
        let id = RegistryFixture.id("a")
        let later = RegistryFixture.epoch.addingTimeInterval(60)

        registry.update(id, state: .reconnecting(attempt: 3), at: later)
        registry.update(id, state: .disconnected(.failed(stateID: "transport.timedOut")), at: later)
        #expect(registry[id]?.reconnectAttempts == 3)

        registry.update(id, state: .disconnected(.closedByUser), at: later)
        #expect(registry[id]?.reconnectAttempts == 0)
    }

    @Test func theRegistryAnswersByConnectionAndByRecentActivity() {
        var registry = SessionRegistry()
        registry.open(RegistryFixture.record("a", connection: "shared", idle: 300))
        registry.open(RegistryFixture.record("b", connection: "shared", idle: 10))
        registry.open(RegistryFixture.record("c", connection: "other", idle: 900))

        #expect(registry.sessions(on: ConnectionID(rawValue: "shared")).count == 2)
        #expect(registry.mostRecentlyActive?.id == RegistryFixture.id("b"))

        registry.touch(RegistryFixture.id("c"), at: RegistryFixture.epoch.addingTimeInterval(5))
        #expect(registry.mostRecentlyActive?.id == RegistryFixture.id("c"))
    }

    @Test func seedingWithADuplicateIdKeepsOneRecord() {
        let registry = SessionRegistry([
            RegistryFixture.record("a", title: "first"),
            RegistryFixture.record("a", title: "second"),
        ])

        #expect(registry.count == 1)
        #expect(registry.titles == ["first"])
    }
}
