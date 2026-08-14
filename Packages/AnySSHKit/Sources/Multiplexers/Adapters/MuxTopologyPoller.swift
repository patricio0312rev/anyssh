import AnySSHCore

public actor MuxTopologyPoller {
    private let adapter: any MultiplexerAdapter
    private var visibility: MuxPollVisibility = .visible

    public init(adapter: any MultiplexerAdapter) {
        self.adapter = adapter
    }

    public func setVisibility(_ visibility: MuxPollVisibility) {
        self.visibility = visibility
    }

    public func pollOnce(
        session: MuxSession.ID,
        run:
            @escaping @Sendable (_ operation: @escaping @Sendable () async throws -> MuxSnapshot)
            async throws -> MuxSnapshot
    ) async throws -> MuxSnapshot {
        try await waitUntilPollingAllowed()
        return try await run { [adapter, session] in
            try await adapter.snapshot(session)
        }
    }

    public func pollLoop(
        session: MuxSession.ID,
        run:
            @escaping @Sendable (_ operation: @escaping @Sendable () async throws -> MuxSnapshot)
            async throws -> MuxSnapshot,
        onSnapshot: @escaping @Sendable (MuxSnapshot) async -> Void
    ) async throws {
        while !Task.isCancelled {
            try await waitUntilPollingAllowed()
            let snapshot = try await run { [adapter, session] in
                try await adapter.snapshot(session)
            }
            try Task.checkCancellation()
            await onSnapshot(snapshot)
            try await waitUntilPollingAllowed()
            guard let interval = MuxPollCadence.interval(for: visibility) else { continue }
            try await Task.sleep(for: interval)
        }
    }

    private func waitUntilPollingAllowed() async throws {
        while MuxPollCadence.interval(for: visibility) == nil {
            try Task.checkCancellation()
            try await Task.sleep(for: .seconds(1))
        }
    }
}
