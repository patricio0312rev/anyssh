import AnySSHCore
import Foundation

public enum ConnectionFactory {
    public static func make(
        remote: Remote,
        secrets: any SecretStore,
        hostKeys: any HostKeyStore,
        connectionID: ConnectionID = ConnectionID(rawValue: UUID().uuidString.lowercased()),
        passwordOverride: String? = nil,
        answering: AuthPromptAnswering? = nil
    ) -> any RemoteConnection {
        let profile = ConnectionProfile(
            connectionID: connectionID,
            target: SessionTarget(remote: remote),
            username: remote.username
        )
        let credentials = ConnectionCredentials {
            try await CredentialResolver.resolve(
                remote: remote,
                secrets: secrets,
                passwordOverride: passwordOverride,
                answering: answering
            )
        }
        return SSHRemoteConnection(
            profile: profile,
            credentials: credentials,
            hostKeys: hostKeys
        )
    }
}
