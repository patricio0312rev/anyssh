public enum HostKeyAlgorithm: String, CaseIterable, Sendable {
    case ed25519
    case ecdsa
    case rsa
    case unknown
}

public struct HostKey: Hashable, Sendable {
    public let algorithm: HostKeyAlgorithm
    public let raw: [UInt8]

    public init(algorithm: HostKeyAlgorithm, raw: [UInt8]) {
        self.algorithm = algorithm
        self.raw = raw
    }
}

public struct HostKeyFingerprint: Hashable, Sendable {
    public let algorithm: HostKeyAlgorithm
    public let digest: [UInt8]

    public init(algorithm: HostKeyAlgorithm, digest: [UInt8]) {
        self.algorithm = algorithm
        self.digest = digest
    }
}

public enum KnownHostStatus: Hashable, Sendable {
    case unknown
    case matches
    case changed(stored: HostKeyFingerprint)
}

public enum HostKeyVerdict: Hashable, Sendable {
    case accept(remember: Bool)
    case reject
    case cancel
}
