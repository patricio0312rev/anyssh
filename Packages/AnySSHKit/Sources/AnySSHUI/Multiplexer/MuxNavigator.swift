import AnySSHCore

public struct MuxNavigator: Sendable {
    public typealias AttachmentProbe = @Sendable () async -> MuxAttachment

    private let adapter: any MultiplexerAdapter
    private let writer: any DisplayWriter
    private let probe: AttachmentProbe

    public init(
        adapter: any MultiplexerAdapter,
        writer: any DisplayWriter,
        probe: @escaping AttachmentProbe
    ) {
        self.adapter = adapter
        self.writer = writer
        self.probe = probe
    }

    public func jump(to target: MuxTarget) async throws -> MuxJumpOutcome {
        try await adapter.focus(target)
        switch await probe() {
        case .detached:
            let bytes = attachBytes(for: target)
            guard !bytes.isEmpty else { throw ErrorState.mux(.attachTargetVanished) }
            try await writer.send(bytes[...])
            return .attached
        case .attached(let bound):
            guard let bound, bound != target.session else { return .focused }
            return .focusedElsewhere(target.session)
        case .unknown:
            return .focused
        }
    }

    public func jump(toSession target: MuxSessionID) async throws -> MuxJumpOutcome {
        switch await probe() {
        case .attached(let bound):
            guard let source = bound else { return .skipped(target) }
            guard source != target else { return .focused }
            return try await switching(to: target, from: source, whenRefused: .skipped(target))
        case .detached:
            let bytes = attachBytes(for: MuxTarget(session: target))
            guard !bytes.isEmpty else { throw ErrorState.mux(.attachTargetVanished) }
            try await writer.send(bytes[...])
            return .attached
        case .unknown:
            return .skipped(target)
        }
    }

    public func attachBytes(for target: MuxTarget) -> [UInt8] {
        let command = adapter.attachCommand(target)
        guard !command.isEmpty else { return [] }
        return Array((command + Self.submit).utf8)
    }

    private func switching(
        to target: MuxSessionID,
        from source: MuxSessionID,
        whenRefused refused: MuxJumpOutcome
    ) async throws -> MuxJumpOutcome {
        do {
            try await adapter.switchSession(to: target, from: source)
            return .attached
        } catch let state as ErrorState where Self.refusals.contains(state) {
            return refused
        }
    }

    private static let refusals: Set<ErrorState> = [
        .mux(.sessionSwitchUnsupported),
        .mux(.attachTargetVanished),
    ]

    private static let submit = "\r"
}
