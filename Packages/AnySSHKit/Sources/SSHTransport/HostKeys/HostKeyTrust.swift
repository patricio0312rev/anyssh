import AnySSHCore

public struct HostKeyTrust: Sendable {
    public let store: any HostKeyStore
    public let question: HostKeyQuestion

    public init(store: any HostKeyStore, question: HostKeyQuestion) {
        self.store = store
        self.question = question
    }

    public static let unattended = HostKeyTrust(
        store: EmptyHostKeyStore(),
        question: .unattended
    )

    public func status(of offered: HostKey, host: String, port: Int) async throws -> KnownHostStatus {
        guard let stored = try await store.knownKey(host: host, port: port) else { return .unknown }
        return stored.matches(offered) ? .matches : .changed(stored: stored.fingerprint)
    }

    public func evaluate(
        _ offered: HostKey,
        host: String,
        port: Int
    ) async throws -> HostKeyTrustOutcome {
        let status = try await status(of: offered, host: host, port: port)
        guard status != .matches else { return .alreadyKnown }

        let verdict = await question(offered, status)
        guard status == .unknown else { return .refused(.hostKeyChanged) }

        switch verdict {
        case .accept(let remember):
            if remember { try await store.remember(offered, host: host, port: port) }
            return .accepted(remembered: remember)
        case .reject:
            return .refused(.rejected)
        case .cancel:
            return .refused(.cancelled)
        }
    }
}

public enum HostKeyTrustOutcome: Hashable, Sendable {
    case alreadyKnown
    case accepted(remembered: Bool)
    case refused(TrustErrorState)

    public var isTrusted: Bool {
        switch self {
        case .alreadyKnown, .accepted: true
        case .refused: false
        }
    }

    public var failure: TransportFailure? {
        guard case .refused(let state) = self else { return nil }
        return TransportFailure(stateID: state.stateID)
    }
}
