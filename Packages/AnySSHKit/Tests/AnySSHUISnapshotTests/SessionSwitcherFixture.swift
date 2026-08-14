import AnySSHCore
import AnySSHMocks
import Foundation
import Observation
import Sessions

@testable import AnySSHUI

@MainActor
@Observable
final class SessionSwitcherFixture: SessionSwitcherPresenting {
    private(set) var registry: SessionRegistry
    private(set) var activeSessionID: SessionID?
    private(set) var isGridMode: Bool
    private(set) var refreshCount = 0
    private(set) var openCount = 0

    private let remotes: [RemoteID: Remote]
    private let agentKinds: [SessionID: AgentKind]

    init(fixture: String = "four", isGridMode: Bool = false) {
        let records = SessionScenario.records(fixture)
        registry = SessionRegistry(records)
        activeSessionID = records.first?.id
        self.isGridMode = isGridMode
        remotes = Dictionary(
            uniqueKeysWithValues: RemoteFixtures.scenario("mixed").map { ($0.id, $0) }
        )
        agentKinds = Dictionary(
            uniqueKeysWithValues: zip(records.map(\.id), AgentKindCatalog.kinds)
        )
    }

    var canOpenAdditionalSession: Bool { activeSessionID != nil }

    func hostAddress(for id: SessionID) -> String {
        guard let record = registry[id], let remote = remotes[record.remoteID] else {
            return registry[id]?.title ?? "Session"
        }
        return remote.endpoint
    }

    func remoteName(for id: SessionID) -> String? {
        registry[id].flatMap { remotes[$0.remoteID]?.name }
    }

    func agentKind(for id: SessionID) -> AgentKind? {
        agentKinds[id]
    }

    func uptime(for id: SessionID) -> String {
        guard let record = registry[id] else { return "" }
        let age = SessionScenario.epoch.timeIntervalSince(record.createdAt)
        guard age >= 1 else { return "just opened" }
        return Duration.seconds(age).formatted(
            .units(allowed: [.days, .hours, .minutes], width: .abbreviated)
        )
    }

    func toggleGridMode() {
        isGridMode.toggle()
    }

    func refreshAgentKinds() async {
        refreshCount += 1
    }

    func openAdditionalSession() async {
        openCount += 1
    }

    func close(_ id: SessionID) async {
        _ = registry.close(id)
        if activeSessionID == id { activeSessionID = registry.sessions.first?.id }
    }
}
