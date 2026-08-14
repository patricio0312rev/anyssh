import AnySSHCore
import Foundation
import Observation
import SSHTransport

@MainActor
@Observable
public final class SessionAuthBridge {
    public let auth: AuthPromptModel
    public let trust: HostKeyTrustModel
    public private(set) var pendingPasswordSave: PendingPasswordSave?
    public private(set) var lastTypedPassword: String?

    private let secrets: any SecretStore
    private let remoteID: RemoteID
    private let adapter: Adapter

    public struct PendingPasswordSave: Equatable, Sendable {
        public let remoteID: RemoteID
        public let password: String
    }

    public init(
        remote: Remote,
        secrets: any SecretStore,
        hostKeys: any HostKeyStore
    ) {
        self.secrets = secrets
        remoteID = remote.id
        auth = AuthPromptModel()
        trust = HostKeyTrustModel(store: hostKeys, host: remote.host, port: remote.port)
        adapter = Adapter()
        adapter.owner = self
    }

    public var delegate: any TerminalTransportDelegate {
        adapter
    }

    public var answering: AuthPromptAnswering {
        { [self] round in await self.answer(round) }
    }

    public func rememberTypedPassword(from answer: AuthPromptAnswer, method: AuthMethod) {
        guard method == .password, case .answers(let values) = answer, let password = values.first,
            !password.isEmpty
        else { return }
        lastTypedPassword = password
    }

    public func offerPasswordSaveIfNeeded() {
        guard let password = lastTypedPassword else { return }
        pendingPasswordSave = PendingPasswordSave(remoteID: remoteID, password: password)
        lastTypedPassword = nil
    }

    public func discardTypedPassword() {
        lastTypedPassword = nil
    }

    public func savePendingPassword() async {
        guard let pending = pendingPasswordSave else { return }
        try? await secrets.store(
            Data(pending.password.utf8),
            at: SecretReference(remoteID: pending.remoteID, kind: .password)
        )
        pendingPasswordSave = nil
    }

    public func dismissPasswordSave() {
        pendingPasswordSave = nil
    }

    fileprivate func answer(_ round: AuthPromptRound) async -> AuthPromptAnswer {
        let answer = await auth.ask(round)
        rememberTypedPassword(from: answer, method: round.method)
        return answer
    }

    fileprivate func verify(
        key: HostKey,
        status: KnownHostStatus
    ) async -> HostKeyVerdict {
        await trust.ask(key, status)
    }
}

private final class Adapter: TerminalTransportDelegate, @unchecked Sendable {
    weak var owner: SessionAuthBridge?

    func transport(
        _ transport: any TerminalTransport,
        verify key: HostKey,
        status: KnownHostStatus
    ) async -> HostKeyVerdict {
        guard let owner else { return .cancel }
        return await owner.verify(key: key, status: status)
    }

    func transport(
        _ transport: any TerminalTransport,
        answer round: AuthPromptRound
    ) async -> AuthPromptAnswer {
        guard let owner else { return .cancelled }
        return await owner.answer(round)
    }

    func transport(_ transport: any TerminalTransport, didChange state: TransportState) async {
        guard case .disconnected = state else { return }
        await owner?.discardTypedPassword()
    }
}
