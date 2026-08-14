import AnySSHCore
import AnySSHMocks
import AnySSHUI
import Foundation
import Observation
import Sessions

@MainActor
@Observable
final class ScenarioSessionSwitcher: SessionSwitcherPresenting {
    private(set) var registry: SessionRegistry
    private(set) var activeSessionID: SessionID?
    private(set) var isGridMode: Bool

    private let remotes: [RemoteID: Remote]
    private let agentKinds: [SessionID: AgentKind]
    private let now: Date

    init(fixture: String, isGridMode: Bool = false) {
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
        now = SessionScenario.epoch
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
        let age = now.timeIntervalSince(record.createdAt)
        guard age >= 1 else { return "just opened" }
        return Duration.seconds(age).formatted(
            .units(allowed: [.days, .hours, .minutes], width: .abbreviated)
        )
    }

    func toggleGridMode() {
        isGridMode.toggle()
    }

    func refreshAgentKinds() async {}

    func openAdditionalSession() async {}

    func close(_ id: SessionID) async {
        _ = registry.close(id)
        if activeSessionID == id { activeSessionID = registry.sessions.first?.id }
    }
}
