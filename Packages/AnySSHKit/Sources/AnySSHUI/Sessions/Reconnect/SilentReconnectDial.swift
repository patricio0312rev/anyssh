import AnySSHCore

enum SilentReconnectDial {
    static func dialsWithoutPrompt(_ remote: Remote, secrets: any SecretStore) async -> Bool {
        guard remote.authMethod == .password else { return false }
        let reference = SecretReference(remoteID: remote.id, kind: .password)
        guard reference.kind.gate == .none else { return false }
        do {
            guard let stored = try await secrets.secret(reference) else { return false }
            return !stored.isEmpty
        } catch {
            return false
        }
    }
}
