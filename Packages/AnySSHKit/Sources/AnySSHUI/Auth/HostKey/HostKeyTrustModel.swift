import AnySSHCore
import Observation
import SSHTransport

@Observable
public final class HostKeyTrustModel {
    public enum Stage: Equatable {
        case idle
        case asking(HostKeyPrompt)
        case refused(TrustErrorState)
    }

    public private(set) var stage: Stage = .idle
    public private(set) var didForget = false

    public let host: String
    public let port: Int

    private let store: any HostKeyStore
    private var pending: CheckedContinuation<HostKeyVerdict, Never>?

    public init(store: any HostKeyStore, host: String, port: Int = 22) {
        self.store = store
        self.host = host
        self.port = port
    }

    public var question: HostKeyQuestion {
        HostKeyQuestion { [self] key, status in await ask(key, status) }
    }

    public func ask(_ key: HostKey, _ status: KnownHostStatus) async -> HostKeyVerdict {
        await withCheckedContinuation { continuation in
            resume(.cancel)
            stage = .asking(HostKeyPrompt(host: host, port: port, offered: key, status: status))
            pending = continuation
        }
    }

    public func accept(remember: Bool = true) {
        stage = .idle
        resume(.accept(remember: remember))
    }

    public func reject() {
        stage = .refused(.rejected)
        resume(.reject)
    }

    public func cancel() {
        stage = .refused(isChanged ? .hostKeyChanged : .cancelled)
        resume(.cancel)
    }

    public func forgetHost() async {
        try? await store.forget(host: host, port: port)
        didForget = true
        stage = .refused(.hostKeyChanged)
        resume(.cancel)
    }

    public func dismiss() {
        stage = .idle
    }

    private var isChanged: Bool {
        guard case .asking(let prompt) = stage else { return false }
        return prompt.isChanged
    }

    private func resume(_ verdict: HostKeyVerdict) {
        guard let continuation = pending else { return }
        pending = nil
        continuation.resume(returning: verdict)
    }
}
