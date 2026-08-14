import AnySSHCore
import Testing

@testable import AnySSHMocks

@Suite struct SessionScenarioTests {
    @Test func theScenarioDrivesFourSessionsWithNoHost() {
        let records = SessionScenario.records()

        #expect(records.count == 4)
        #expect(Set(records.map(\.id)).count == 4)
        #expect(Set(records.map(\.connectionID)).count == 4)
        #expect(records.allSatisfy { !$0.title.isEmpty })
    }

    @Test func twoOfTheFourShareARemoteOnSeparateConnections() {
        let records = SessionScenario.records()
        let workstation = records.filter { $0.remoteID == RemoteFixtures.workstation.id }

        #expect(workstation.count == 2)
        #expect(workstation[0].connectionID != workstation[1].connectionID)
    }

    @Test func theFourStatesAreDistinguishableAndTheAttemptCountMatchesTheState() {
        let records = SessionScenario.records()
        let retrying = records.first { $0.id == SessionID(rawValue: "session-3") }

        #expect(Set(records.map(\.state)).count == 3)
        #expect(retrying?.state == .reconnecting(attempt: 2))
        #expect(retrying?.reconnectAttempts == 2)
        #expect(records.contains { $0.capabilities.serverSideResume })
    }

    @Test func everyDateIsFrozenSoAScreenshotSweepAgreesWithItself() {
        let records = SessionScenario.records()

        #expect(records.allSatisfy { $0.createdAt < SessionScenario.epoch })
        #expect(records.allSatisfy { $0.createdAt <= $0.lastActiveAt })
        #expect(SessionScenario.records() == records)
    }

    @Test func theNamedScenariosSelectTheirOwnSize() {
        #expect(SessionScenario.records("empty").isEmpty)
        #expect(SessionScenario.records("single").count == 1)
        #expect(SessionScenario.records("four").count == 4)
    }
}
