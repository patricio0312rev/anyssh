public protocol HostKeyStore: Sendable {
    func knownKey(host: String, port: Int) async throws -> HostKey?
    func remember(_ key: HostKey, host: String, port: Int) async throws
    func forget(host: String, port: Int) async throws
}
