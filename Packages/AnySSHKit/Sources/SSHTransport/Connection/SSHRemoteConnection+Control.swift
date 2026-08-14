import AnySSHCore
import Foundation

extension SSHRemoteConnection {
    public func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        let control = try await connectedControl()
        defer { lastControlActivity = .now }
        return try await register { try await control.run(batch) }
    }

    public func execute(_ command: String) async throws -> Data {
        let control = try await connectedControl()
        defer { lastControlActivity = .now }
        return try await register { try await control.execute(command) }
    }

    public func uploadFile(_ file: URL, command: String) async throws {
        let control = try await connectedControl()
        defer { lastControlActivity = .now }
        try await register { try await control.uploadFile(file, command: command) }
    }

    func connectedControl() async throws -> ControlTransport {
        guard !isClosed else { throw TransportFailure.connectionClosed }
        if let control, await control.isConnected { return control }
        let control = self.control ?? makeControlTransport()
        self.control = control
        controlState = .connecting
        do {
            try await control.connect(
                credential: try await credential(for: .control),
                trust: controlTrust(),
                answering: controlAnswering(),
                roundTimeout: profile.display.roundTimeout
            )
        } catch {
            self.control = nil
            controlState = .disconnected(.failed(stateID: Self.stateID(of: error)))
            throw error
        }
        controlState = .connected
        lastControlActivity = .now
        startIdleSweep()
        return control
    }

    public func reconnectControl() async throws {
        if let control {
            await control.close(reason: .closedByUser)
        }
        control = nil
        controlState = .connecting
        _ = try await connectedControl()
    }

    func noteControlFailure(_ error: any Error) async {
        guard let failure = error as? TransportFailure, Self.isFatal(failure) else { return }
        if let control {
            await control.close(reason: .failed(stateID: failure.stateID))
        }
        control = nil
        controlState = .disconnected(.failed(stateID: failure.stateID))
    }

    func startIdleSweep() {
        guard idleSweeper == nil else { return }
        let tick = max(.milliseconds(10), profile.controlIdleTTL / 4)
        idleSweeper = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: tick)
                guard let self, await self.sweepIdleControl() else { return }
            }
        }
    }

    func sweepIdleControl() async -> Bool {
        guard let control else {
            idleSweeper = nil
            return false
        }
        guard work.isEmpty, lastControlActivity.duration(to: .now) >= profile.controlIdleTTL else {
            return true
        }
        await control.close(reason: .backgrounded)
        self.control = nil
        controlState = .disconnected(.backgrounded)
        idleSweeper = nil
        return false
    }

    func makeControlTransport() -> ControlTransport {
        ControlTransport(
            target: profile.target,
            username: profile.username,
            configuration: profile.control,
            ledger: ledger
        )
    }

    func controlTrust() -> HostKeyTrust {
        HostKeyTrust(
            store: hostKeys,
            question: HostKeyQuestion { [weak self] key, status in
                await self?.askVerify(key, status) ?? .cancel
            }
        )
    }

    func controlAnswering() -> AuthPromptAnswering? {
        guard delegate != nil else { return nil }
        return { [weak self] round in
            await self?.askAnswer(round) ?? .cancelled
        }
    }

    private func askVerify(_ key: HostKey, _ status: KnownHostStatus) async -> HostKeyVerdict {
        guard let delegate, let display = try? await displayTransport() else { return .cancel }
        return await delegate.transport(display, verify: key, status: status)
    }

    private func askAnswer(_ round: AuthPromptRound) async -> AuthPromptAnswer {
        guard let delegate, let display = try? await displayTransport() else { return .cancelled }
        return await delegate.transport(display, answer: round)
    }

    static func isFatal(_ failure: TransportFailure) -> Bool {
        [
            TransportFailure.notConnected.stateID,
            TransportFailure.keepaliveTimeout.stateID,
            "transport.connectionLost",
        ].contains(failure.stateID)
    }

    static func stateID(of error: any Error) -> String {
        (error as? any UserFacingError)?.stateID ?? "transport.connectionLost"
    }
}
