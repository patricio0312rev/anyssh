import AnySSHCore
import Foundation

public enum CredentialResolver {
    public static func resolve(
        remote: Remote,
        secrets: any SecretStore,
        passwordOverride: String? = nil,
        answering: AuthPromptAnswering? = nil
    ) async throws -> AuthCredential {
        switch remote.authMethod {
        case .password:
            return try await password(
                remote: remote,
                secrets: secrets,
                override: passwordOverride,
                answering: answering
            )
        case .publicKey:
            return try await privateKey(for: remote.id, secrets: secrets)
        case .keyboardInteractive:
            return .keyboardInteractive
        }
    }

    private static func password(
        remote: Remote,
        secrets: any SecretStore,
        override: String?,
        answering: AuthPromptAnswering?
    ) async throws -> AuthCredential {
        if let override, !override.isEmpty {
            return .password(override)
        }
        if let data = try await secrets.secret(SecretReference(remoteID: remote.id, kind: .password)),
            let stored = String(data: data, encoding: .utf8),
            !stored.isEmpty
        {
            return .password(stored)
        }
        guard let answering else {
            throw ErrorState.auth(.passwordRejected)
        }
        let answer = await answering(AuthPromptRound.password(username: remote.username))
        switch answer {
        case .answers(let values):
            guard let typed = values.first, !typed.isEmpty else {
                throw ErrorState.auth(.passwordRejected)
            }
            return .password(typed)
        case .cancelled:
            throw ErrorState.auth(.keyboardInteractiveCancelled)
        case .failed(let stateID):
            throw ErrorState(stateID: stateID) ?? ErrorState.auth(.passwordRejected)
        }
    }

    private static func privateKey(
        for remoteID: RemoteID,
        secrets: any SecretStore
    ) async throws -> AuthCredential {
        let keyRef = SecretReference(remoteID: remoteID, kind: .privateKey)
        let passphraseRef = SecretReference(remoteID: remoteID, kind: .keyPassphrase)
        let resolved = try await secrets.secrets(gated: [keyRef, passphraseRef])
        guard let keyData = resolved[keyRef] ?? nil, !keyData.isEmpty else {
            throw ErrorState.auth(.publicKeyRejected)
        }
        let passphrase =
            keyRequiresPassphrase(keyData) ? storedPassphrase(resolved[passphraseRef] ?? nil) : nil
        return .privateKey(AuthPrivateKey(privateKey: keyData, passphrase: passphrase))
    }

    private static func storedPassphrase(_ data: Data?) -> String? {
        data.flatMap { String(data: $0, encoding: .utf8) }.flatMap { $0.isEmpty ? nil : $0 }
    }

    private static func keyRequiresPassphrase(_ keyData: Data) -> Bool {
        do {
            return try KeyMaterialParser.parse(KeyMaterialBuffer(keyData)).isEncrypted
        } catch {
            return true
        }
    }
}
