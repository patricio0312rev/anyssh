import AnySSHCore

public enum HostKeyBlob {
    public static let ed25519Name = "ssh-ed25519"
    public static let rsaName = "ssh-rsa"

    public static func typeName(of raw: [UInt8]) -> String? {
        guard raw.count >= 4 else { return nil }
        let length =
            Int(raw[0]) << 24 | Int(raw[1]) << 16 | Int(raw[2]) << 8 | Int(raw[3])
        guard length > 0, length <= 64, raw.count >= 4 + length else { return nil }
        let name = String(decoding: raw[4..<(4 + length)], as: UTF8.self)
        return name.allSatisfy { $0.isASCII && !$0.isWhitespace } ? name : nil
    }

    public static func algorithm(named name: String) -> HostKeyAlgorithm {
        switch name {
        case ed25519Name: .ed25519
        case rsaName, "rsa-sha2-256", "rsa-sha2-512": .rsa
        case let name where name.hasPrefix("ecdsa-sha2-"): .ecdsa
        default: .unknown
        }
    }

    public static func algorithm(of raw: [UInt8]) -> HostKeyAlgorithm {
        guard let name = typeName(of: raw) else { return .unknown }
        return algorithm(named: name)
    }

    public static func canonicalName(for algorithm: HostKeyAlgorithm) -> String? {
        switch algorithm {
        case .ed25519: ed25519Name
        case .rsa: rsaName
        case .ecdsa: "ecdsa-sha2-nistp256"
        case .unknown: nil
        }
    }
}

extension HostKey {
    public init(blob: [UInt8]) {
        self.init(algorithm: HostKeyBlob.algorithm(of: blob), raw: blob)
    }

    public var typeName: String {
        HostKeyBlob.typeName(of: raw)
            ?? HostKeyBlob.canonicalName(for: algorithm)
            ?? "unknown"
    }
}
