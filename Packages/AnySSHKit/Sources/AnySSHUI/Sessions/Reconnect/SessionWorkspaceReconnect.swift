import AnySSHCore
import Foundation
import Sessions

extension SessionWorkspaceModel {
    public func startReconnectMonitoring() {
        reconnectCoordinator.start(
            candidates: { [weak self] in
                self?.registry.sessions ?? []
            },
            onReconnect: { [weak self] id in
                await self?.reconnect(id)
            }
        )
    }

    public func stopReconnectMonitoring() {
        reconnectCoordinator.stop()
        #if canImport(UIKit)
        backgroundTask.end()
        #endif
    }

    public func handleForeground() {
        #if canImport(UIKit)
        backgroundTask.end()
        #endif
        reconnectCoordinator.handleForeground()
    }

    public func handleBackground() {
        #if canImport(UIKit)
        backgroundTask.begin { [weak self] in
            self?.markBackgroundedSessions()
        }
        #endif
    }

    public func reconnect(_ id: SessionID, forced: Bool = false) async {
        guard let record = registry[id], let remote = remotes[record.remoteID] else { return }
        guard let plan = reconnectPlan(for: record, forced: forced) else { return }
        updateTransportState(.reconnecting(attempt: plan.attempt), for: id)
        if plan.delay > .zero {
            try? await Task.sleep(for: plan.delay)
        }
        await performReconnect(id, remote: remote, attempt: plan.attempt)
    }

    private func reconnectPlan(
        for record: SessionRecord,
        forced: Bool
    ) -> (attempt: Int, delay: Duration)? {
        switch reconnectCoordinator.decision(for: record) {
        case .leaveAlone:
            return nil
        case .reconnect(let attempt, let delay):
            return (attempt, delay)
        case .waitForUser:
            guard forced else { return nil }
            return (max(1, record.reconnectAttempts + 1), .zero)
        case .exhausted:
            if forced {
                return (max(1, record.reconnectAttempts + 1), .zero)
            }
            updateTransportState(
                .disconnected(
                    .failed(stateID: ErrorState.session(.reconnectExhausted).stateID)
                ),
                for: record.id
            )
            return nil
        }
    }

    public func markBackgroundedSessions() {
        let now = Date.now
        for record in registry.sessions where SessionOpenService.isLive(record.state) {
            if case .connected = record.state {
                updateTransportState(.disconnected(.backgrounded), for: record.id, at: now)
            }
        }
    }

    func presentReattached(for title: String) {
        let state = ErrorState.session(.reattached)
        statusToasts?.present(
            severity: .success,
            title: "\(state.copy.title) to \(title)",
            body: state.copy.body,
            accessibilityIdentifier: UIIdentifier.Session.reattached
        )
    }

    private func performReconnect(
        _ sessionID: SessionID,
        remote: Remote,
        attempt: Int
    ) async {
        guard let makeConnection else {
            updateTransportState(
                .disconnected(.failed(stateID: ErrorState.transport(.connectionRefused).stateID)),
                for: sessionID
            )
            return
        }
        if let old = connections.removeValue(forKey: sessionID) {
            await old.close(reason: .backgrounded)
        }
        scopes.removeValue(forKey: sessionID)
        let bridge = makeAuthBridge(for: remote)
        let connection = makeConnection(remote, bridge)
        connections[sessionID] = connection
        if let bridge {
            authBridges[sessionID] = bridge
            if activeSessionID == sessionID {
                activeAuthBridge = bridge
            }
        }
        let surface = attach(sessionID, connection: connection)
        do {
            if let bridge {
                await connection.setDisplayDelegate(bridge.delegate)
            }
            try await connection.attachDisplay(sink: surface.pump, size: surface.engine.size)
            try await StartupCommandSender().send(on: connection, remote: remote)
            try? await WorkingDirectoryRestorer().send(
                on: connection,
                workspace: registry[sessionID]?.workspace
            )
            clearOpenFailure()
            updateTransportState(.connected, for: sessionID)
            presentReattached(for: registry[sessionID]?.title ?? remote.name)
            surface.startDraining()
        } catch let error as any UserFacingError {
            let state = ErrorState(stateID: error.stateID) ?? .transport(.connectionRefused)
            let stateID =
                ReconnectBackoff.standard.nextAttempt(after: attempt) == nil
                ? ErrorState.session(.reconnectExhausted).stateID
                : state.stateID
            updateTransportState(.disconnected(.failed(stateID: stateID)), for: sessionID)
        } catch {
            updateTransportState(
                .disconnected(
                    .failed(stateID: ErrorState.transport(.connectionRefused).stateID)
                ),
                for: sessionID
            )
        }
    }
}
