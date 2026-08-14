import AnySSHCore

struct EmptyHostKeyStore: HostKeyStore {
    func knownKey(host: String, port: Int) async throws -> HostKey? { nil }

    func remember(_ key: HostKey, host: String, port: Int) async throws {}

    func forget(host: String, port: Int) async throws {}
}
