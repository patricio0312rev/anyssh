import AnySSHCore
import Observation
import Sessions

@MainActor
public protocol SessionSwitcherPresenting: AnyObject, Observable {
    var registry: SessionRegistry { get }
    var activeSessionID: SessionID? { get }
    var isGridMode: Bool { get }
    var canOpenAdditionalSession: Bool { get }

    func hostAddress(for id: SessionID) -> String
    func remoteName(for id: SessionID) -> String?
    func agentKind(for id: SessionID) -> AgentKind?
    func uptime(for id: SessionID) -> String

    func toggleGridMode()
    func refreshAgentKinds() async
    func openAdditionalSession() async
    func close(_ id: SessionID) async
}
