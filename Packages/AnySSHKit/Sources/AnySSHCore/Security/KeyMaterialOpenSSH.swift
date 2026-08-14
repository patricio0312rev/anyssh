struct SSHWireReader {
    private let bytes: [UInt8]
    private var offset: Int

    init(_ bytes: [UInt8], from offset: Int = 0) {
        self.bytes = bytes
        self.offset = offset
    }

    mutating func uint32() -> UInt32? {
        guard offset + 4 <= bytes.count else { return nil }
        defer { offset += 4 }
        return bytes[offset..<offset + 4].reduce(UInt32(0)) { $0 << 8 | UInt32($1) }
    }

    mutating func field() -> [UInt8]? {
        guard let length = uint32(), let count = Int(exactly: length),
            offset + count <= bytes.count
        else { return nil }
        defer { offset += count }
        return Array(bytes[offset..<offset + count])
    }

    mutating func text() -> String? {
        field().map { String(decoding: $0, as: UTF8.self) }
    }
}

enum OpenSSHPrivateKey {
    static let magic = Array("openssh-key-v1\u{0}".utf8)

    static func describe(_ body: [UInt8]) throws -> KeyMaterial {
        guard body.count > magic.count, Array(body[0..<magic.count]) == magic else {
            throw KeyMaterialError.unreadable(.openSSH)
        }

        var reader = SSHWireReader(body, from: magic.count)
        guard let cipher = reader.text(), reader.text() != nil, reader.field() != nil,
            let keyCount = reader.uint32(), keyCount > 0, let publicBlob = reader.field()
        else { throw KeyMaterialError.truncated(.openSSH) }

        var blob = SSHWireReader(publicBlob)
        guard let wireName = blob.text() else { throw KeyMaterialError.unreadable(.openSSH) }
        let algorithm = PrivateKeyAlgorithm(wireName: wireName)

        return KeyMaterial(
            format: .openSSH,
            algorithm: algorithm,
            isEncrypted: cipher != "none",
            bitCount: bitCount(of: algorithm, in: &blob),
            fingerprint: SSHFingerprint.sha256(ofPublicBlob: publicBlob)
        )
    }

    private static func bitCount(
        of algorithm: PrivateKeyAlgorithm,
        in blob: inout SSHWireReader
    ) -> Int? {
        switch algorithm {
        case .ed25519:
            return 256
        case .rsa:
            guard blob.field() != nil, let modulus = blob.field() else { return nil }
            return SSHFingerprint.bitCount(ofMagnitude: modulus)
        case .dsa:
            return 1024
        case .ecdsa, .unknown:
            return nil
        }
    }
}
