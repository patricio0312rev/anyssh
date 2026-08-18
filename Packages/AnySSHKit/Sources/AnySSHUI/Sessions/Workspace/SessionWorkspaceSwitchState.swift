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
            let sessionID = activeSessionID, let connection = connections[sessionID]
        else {
            pendingPane = nil
            return
        }
        pendingPane = nil
        let navigator = MuxNavigator(
            adapter: adapter,
            writer: connection,
            probe: attachmentProbe(for: sessionID)
        )
        Task { [weak self] in
            await self?.focusPendingPane(pane, of: sessionID, using: adapter, through: navigator)
        }
    }

    private func focusPendingPane(
        _ pane: MuxPaneID,
        of sessionID: SessionID,
        using adapter: any MultiplexerAdapter,
        through navigator: MuxNavigator
    ) async {
        do {
            let sessions = try await adapter.listSessions()
            guard let session = muxSession(in: sessions, for: sessionID) else {
                throw ErrorState.mux(.attachTargetVanished)
            }
            let outcome = try await navigator.jump(
                to: MuxTarget(session: session.id, pane: pane)
            )
            guard case .focusedElsewhere = outcome else { return }
            statusToasts?.present(
                severity: .attention,
                title: MuxNavigationCopy.focused(in: session.name),
                body: MuxNavigationCopy.detachToSwitch
            )
        } catch {
            statusToasts?.present(state: (error as? ErrorState) ?? .mux(.attachTargetVanished))
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
