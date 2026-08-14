import AnySSHCore

public enum ReconnectDecision: Hashable, Sendable {
    case reconnect(attempt: Int, delay: Duration)
    case waitForUser
    case exhausted
    case leaveAlone

    public var shouldDial: Bool {
        if case .reconnect = self { return true }
        return false
    }
}

public struct ReconnectPolicy: Sendable {
    public let backoff: ReconnectBackoff

    public init(backoff: ReconnectBackoff = .standard) {
        self.backoff = backoff
    }

    public func decision(
        state: TransportState,
        capabilities: TransportCapabilities,
        recordedAttempts: Int
    ) -> ReconnectDecision {
        switch state {
        case .connected, .connecting, .authenticating, .idle:
            return .leaveAlone
        case .reconnecting(let attempt):
            guard backoff.allows(attempt: attempt) else { return .exhausted }
            return .reconnect(attempt: attempt, delay: backoff.delay(beforeAttempt: attempt))
        case .disconnected(let reason):
            return afterDisconnect(
                reason,
                capabilities: capabilities,
                recordedAttempts: recordedAttempts
            )
        }
    }

    public func survivalCopy(for capabilities: TransportCapabilities) -> ErrorState {
        ReconnectSurvivalCopy.state(for: capabilities)
    }

    private func afterDisconnect(
        _ reason: DisconnectReason,
        capabilities: TransportCapabilities,
        recordedAttempts: Int
    ) -> ReconnectDecision {
        switch reason {
        case .closedByUser:
            return .leaveAlone
        case .closedByRemote, .backgrounded, .cancelledBySwitch:
            break
        case .failed:
            break
        }

        if capabilities.roaming {
            return nextAutomatic(after: recordedAttempts)
        }

        switch reason {
        case .backgrounded:
            return nextAutomatic(after: recordedAttempts)
        case .closedByRemote, .cancelledBySwitch, .failed:
            return recordedAttempts >= backoff.maxAttempts ? .exhausted : .waitForUser
        case .closedByUser:
            return .leaveAlone
        }
    }

    private func nextAutomatic(after recordedAttempts: Int) -> ReconnectDecision {
        guard let attempt = backoff.nextAttempt(after: recordedAttempts) else {
            return .exhausted
        }
        return .reconnect(attempt: attempt, delay: backoff.delay(beforeAttempt: attempt))
    }
}
