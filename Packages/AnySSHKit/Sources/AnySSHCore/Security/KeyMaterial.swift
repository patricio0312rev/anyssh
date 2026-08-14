public enum PrivateKeyFormat: String, CaseIterable, Sendable, Hashable {
    case openSSH = "OPENSSH PRIVATE KEY"
    case rsaPKCS1 = "RSA PRIVATE KEY"
    case dsaPKCS1 = "DSA PRIVATE KEY"
    case ecSEC1 = "EC PRIVATE KEY"
    case pkcs8 = "PRIVATE KEY"
    case pkcs8Encrypted = "ENCRYPTED PRIVATE KEY"

    public var beginLine: String { "-----BEGIN \(rawValue)-----" }

    public var endLine: String { "-----END \(rawValue)-----" }

    public var label: String {
        switch self {
        case .openSSH: "OpenSSH"
        case .rsaPKCS1: "PEM RSA"
        case .dsaPKCS1: "PEM DSA"
        case .ecSEC1: "PEM EC"
        case .pkcs8: "PEM PKCS#8"
        case .pkcs8Encrypted: "PEM PKCS#8 encrypted"
        }
    }

    public static let suggested: [PrivateKeyFormat] = [.openSSH, .rsaPKCS1]
}

public enum PrivateKeyAlgorithm: String, CaseIterable, Sendable, Hashable {
    case ed25519
    case rsa
    case ecdsa
    case dsa
    case unknown

    public init(wireName: String) {
        switch wireName {
        case "ssh-ed25519", "sk-ssh-ed25519@openssh.com": self = .ed25519
        case "ssh-rsa", "rsa-sha2-256", "rsa-sha2-512": self = .rsa
        case "ssh-dss": self = .dsa
        default: self = wireName.hasPrefix("ecdsa-sha2-") ? .ecdsa : .unknown
        }
    }

    public var label: String {
        switch self {
        case .ed25519: "ED25519"
        case .rsa: "RSA"
        case .ecdsa: "ECDSA"
        case .dsa: "DSA"
        case .unknown: "Unknown"
        }
    }
}

public struct KeyMaterial: Hashable, Sendable, CustomStringConvertible, CustomDebugStringConvertible {
    public let format: PrivateKeyFormat
    public let algorithm: PrivateKeyAlgorithm
    public let isEncrypted: Bool
    public let bitCount: Int?

    public let fingerprint: String?

    public init(
        format: PrivateKeyFormat,
        algorithm: PrivateKeyAlgorithm,
        isEncrypted: Bool,
        bitCount: Int? = nil,
        fingerprint: String? = nil
    ) {
        self.format = format
        self.algorithm = algorithm
        self.isEncrypted = isEncrypted
        self.bitCount = bitCount
        self.fingerprint = fingerprint
    }

    public var summary: String {
        let bits = bitCount.map(String.init) ?? "?"
        return "\(bits) \(fingerprint ?? "no fingerprint") (\(algorithm.label))"
    }

    public var description: String {
        "KeyMaterial(\(format.label), \(summary), locked: \(isEncrypted))"
    }

    public var debugDescription: String {
        description
    }
}
