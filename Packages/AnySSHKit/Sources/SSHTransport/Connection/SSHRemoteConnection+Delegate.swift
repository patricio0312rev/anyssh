import AnySSHCore

extension SSHRemoteConnection: TerminalTransportDelegate {
    public func transport(
        _ transport: any TerminalTransport,
        verify key: HostKey,
        status: KnownHostStatus
    ) async -> HostKeyVerdict {
        guard let delegate else { return .cancel }
        return await delegate.transport(transport, verify: key, status: status)
    }

    public func transport(
        _ transport: any TerminalTransport,
        answer round: AuthPromptRound
    ) async -> AuthPromptAnswer {
        guard let delegate else { return .cancelled }
        return await delegate.transport(transport, answer: round)
    }

    public func transport(
        _ transport: any TerminalTransport,
        didChange state: TransportState
    ) async {
        displayState = state
        await delegate?.transport(transport, didChange: state)
    }
}
