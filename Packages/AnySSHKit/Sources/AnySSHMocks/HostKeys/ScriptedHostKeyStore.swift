import AnySSHCore

public actor ScriptedHostKeyStore: HostKeyStore {
    public enum Scenario: Sendable {
        case unknownHost
        case knownAndMatching(HostKey)
        case knownAndChanged(stored: HostKey)
    }

    public enum Write: Hashable, Sendable {
        case remembered(HostKey, host: String, port: Int)
        case forgotten(host: String, port: Int)
    }

    public private(set) var writes = [Write]()

    private var keys: [Key: HostKey]

    public init(scenario: Scenario, host: String = "mock.local", port: Int = 22) {
        switch scenario {
        case .unknownHost:
            keys = [:]
        case .knownAndMatching(let key), .knownAndChanged(let key):
            keys = [Key(host: host, port: port): key]
        }
    }

    public init(keys: [String: HostKey] = [:], port: Int = 22) {
        self.keys = Dictionary(
            uniqueKeysWithValues: keys.map { (Key(host: $0.key, port: port), $0.value) }
        )
    }

    public func knownKey(host: String, port: Int) async throws -> HostKey? {
        keys[Key(host: host, port: port)]
    }

    public func remember(_ key: HostKey, host: String, port: Int) async throws {
        keys[Key(host: host, port: port)] = key
        writes.append(.remembered(key, host: host, port: port))
    }

    public func forget(host: String, port: Int) async throws {
        keys[Key(host: host, port: port)] = nil
        writes.append(.forgotten(host: host, port: port))
    }

    public var wroteNothing: Bool {
        writes.isEmpty
    }

    private struct Key: Hashable, Sendable {
        let host: String
        let port: Int
    }
}
