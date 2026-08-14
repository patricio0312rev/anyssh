import AnySSHCore

extension SSHTerminalTransport {
    public func start(size: TerminalSize) async throws {
        guard let sink else { throw TransportFailure.noSink }
        guard session == nil else { throw TransportFailure.alreadyStarted }

        self.size = size
        let session = SSHSession(
            target: target,
            configuration: configuration.session,
            trust: trust()
        )
        self.session = session

        do {
            await transition(to: .connecting)
            try await session.open()
            await transition(to: .authenticating)
            try await session.authenticate(
                as: username,
                with: credential,
                answering: answering(),
                roundTimeout: configuration.roundTimeout
            )
            let channel = try await session.openShell(term: configuration.term, size: size)
            self.channel = channel
            reader = readLoop(session: session, channel: channel, sink: sink)
            await transition(to: .connected)
        } catch {
            await stopped(by: error)
            throw error
        }
    }

    private func trust() -> HostKeyTrust {
        guard let delegate else {
            return HostKeyTrust(store: hostKeys, question: .unattended)
        }
        return HostKeyTrust(store: hostKeys, question: .delegate(delegate, of: self))
    }

    private func answering() -> AuthPromptAnswering? {
        guard let delegate else { return nil }
        return { [self] round in
            await delegate.transport(self, answer: round)
        }
    }

    private func readLoop(
        session: SSHSession,
        channel: SSHChannel,
        sink: any ByteSink
    ) -> Task<Void, Never> {
        Task { [weak self] in
            do {
                try await session.streamShell(channel, into: sink)
                await self?.readingStopped(nil)
            } catch {
                await self?.readingStopped(error)
            }
        }
    }

    func readingStopped(_ error: (any Error)?) async {
        guard case .connected = state else { return }
        guard let error else {
            return await teardown(reason: .closedByRemote)
        }
        guard !(error is CancellationError) else { return }
        await stopped(by: error)
    }

    private func stopped(by error: any Error) async {
        let stateID = (error as? any UserFacingError)?.stateID ?? "transport.connectionLost"
        await teardown(reason: .failed(stateID: stateID))
    }
}
