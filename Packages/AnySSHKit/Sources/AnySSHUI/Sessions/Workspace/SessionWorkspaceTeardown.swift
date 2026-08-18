import AnySSHCore
import Foundation
import Sessions

extension SessionWorkspaceModel {
    func startDisplay(
        sessionID: SessionID,
        remoteID: RemoteID,
        surface: TerminalSurface,
        connection: any RemoteConnection,
        bridge: SessionAuthBridge?,
        remoteName: String
    ) async {
        do {
            if let bridge {
                await connection.setDisplayDelegate(bridge.delegate)
            }
            try await connection.attachDisplay(sink: surface.pump, size: surface.engine.size)
            clearOpenFailure()
            updateTransportState(.connected, for: sessionID)
            if let record = registry[sessionID] {
                await activityCoordinator?.open(
                    record,
                    remoteName: remoteName,
                    agentState: agentStates[sessionID] ?? Self.idleAgentState
                )
            }
            bridge?.offerPasswordSaveIfNeeded()
            await restoreDirectory(for: sessionID, connection: connection)
            await configureMultiplexer(for: sessionID, connection: connection)
        } catch let error as any UserFacingError {
            let state = ErrorState(stateID: error.stateID) ?? .transport(.connectionRefused)
            await abortOpen(sessionID, remoteID: remoteID, state: state)
        } catch {
            await abortOpen(
                sessionID,
                remoteID: remoteID,
                state: .transport(.connectionRefused)
            )
        }
    }

    func abortOpen(
        _ sessionID: SessionID,
        remoteID: RemoteID,
        state: ErrorState
    ) async {
        recordOpenFailure(state, remoteID: remoteID)
        let wasActive = activeSessionID == sessionID
        await tearDown(sessionID, reason: .failed(stateID: state.stateID))
        guard wasActive else { return }
        promoteNextSession()
    }

    func tearDown(_ id: SessionID, reason: DisconnectReason) async {
        if pendingSwitch?.id == id { clearPendingSwitch() }
        if let scope = scopes.removeValue(forKey: id) {
            await scope.cancelAll(reason: reason)
        }
        connections.removeValue(forKey: id)
        sessionAdapters.removeValue(forKey: id)
        sessionAgentKinds.removeValue(forKey: id)
        sessionAgentTitles.removeValue(forKey: id)
        publishedAgentTitleIDs.remove(id)
        agentStates.removeValue(forKey: id)
        barModels.removeValue(forKey: id)
        stallWatchers.removeValue(forKey: id)?.cancel()
        authBridges.removeValue(forKey: id)?.discardTypedPassword()
        await store.close(id, reason: reason)
        await activityCoordinator?.close(id)
        _ = registry.close(id)
    }

    func promoteNextSession() {
        if let next = registry.mostRecentlyActive?.id {
            activate(next)
            store.surface(for: next)?.startDraining()
            registry.touch(next, at: Date.now)
        } else {
            activeSessionID = nil
            activeAuthBridge = nil
        }
    }
}
