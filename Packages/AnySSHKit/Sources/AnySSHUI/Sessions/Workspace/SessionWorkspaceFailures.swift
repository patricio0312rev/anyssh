import AnySSHCore
import Sessions

extension SessionWorkspaceModel {
    public var activeFailure: ErrorState? {
        if let id = activeSessionID,
            case .disconnected(.failed(let stateID)) = registry[id]?.state
        {
            return ErrorState(stateID: stateID)
                ?? openFailure
                ?? .transport(.connectionRefused)
        }
        if activeSessionID == nil { return openFailure }
        return nil
    }

    public var activeSurvivalState: ErrorState? {
        guard let record = activeRecord else { return nil }
        guard let reconnect = registry.reconnectState(for: record.id), reconnect.offersReconnect
        else {
            return nil
        }
        return ReconnectSurvivalCopy.state(for: record.capabilities)
    }

    public var canRetryActiveSession: Bool {
        if let id = activeSessionID {
            return registry.reconnectState(for: id)?.offersReconnect == true
        }
        return openFailure != nil && openFailureRemoteID != nil
    }
}
