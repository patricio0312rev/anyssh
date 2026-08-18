import AnySSHCore
import Foundation
import Multiplexers
import Sessions

extension SessionWorkspaceModel {
    func activate(_ id: SessionID) {
        activeSessionID = id
        activeAuthBridge = authBridges[id]
    }

    func updateActivity(for id: SessionID) {
        guard let record = registry[id], let remoteName = remoteName(for: id) else { return }
        Task {
            await activityCoordinator?.update(
                record,
                remoteName: remoteName,
                agentState: agentStates[id] ?? Self.idleAgentState
            )
        }
    }

    func updateTransportState(_ state: TransportState, for id: SessionID, at date: Date = .now) {
        registry.update(id, state: state, at: date)
        updateActivity(for: id)
    }

    public func endActivities() async {
        for id in registry.ids {
            await activityCoordinator?.close(id)
        }
    }

    func attachPendingPane() {
        guard let pane = pendingPane, let adapter = activeMultiplexerAdapter,
            let connection = activeSessionID.flatMap({ connections[$0] })
        else {
            pendingPane = nil
            return
        }
        pendingPane = nil
        let sessionID = activeSessionID
        Task { [weak self, adapter, connection, sessionID] in
            let sessions = (try? await adapter.listSessions()) ?? []
            guard let sessionID,
                let session = await MainActor.run(body: {
                    self?.muxSession(in: sessions, for: sessionID)
                })
            else { return }
            let command = adapter.attachCommand(MuxTarget(session: session.id, pane: pane))
            try? await connection.sendDisplay(Array((command + "\r").utf8)[...])
        }
    }

    func clearPendingSwitch() { pendingSwitch = nil }

    func markPendingSwitch(to id: SessionID) {
        pendingSwitch = (id, signpost.begin())
    }

    func takePendingTarget() -> SessionID? {
        guard let (target, _) = pendingSwitch else { return nil }
        return target
    }

    func endPendingSwitch(ifMatches id: SessionID) {
        guard let (pendingID, handle) = pendingSwitch, pendingID == id else { return }
        pendingSwitch = nil
        signpost.end(handle)
    }

    func makeAuthBridge(for remote: Remote) -> SessionAuthBridge? {
        guard let secrets, let hostKeys else { return nil }
        return SessionAuthBridge(remote: remote, secrets: secrets, hostKeys: hostKeys)
    }

    static let idleAgentState = "idle"
}
