import CryptoKit
import Foundation

enum PEMPrivateKey {
    static let encryptedProcType = "4,ENCRYPTED"

    static func describe(
        format: PrivateKeyFormat,
        headers: [String: String],
        body: [UInt8]
    ) throws -> KeyMaterial {
        let locked = format == .pkcs8Encrypted || headers["Proc-Type"] == encryptedProcType
        guard !locked else {
            return KeyMaterial(format: format, algorithm: algorithm(of: format), isEncrypted: true)
        }

        switch format {
        case .rsaPKCS1:
            return try rsa(format: format, pkcs1: body)
        case .pkcs8:
            return try pkcs8(body)
        case .dsaPKCS1, .ecSEC1:
            return KeyMaterial(format: format, algorithm: algorithm(of: format), isEncrypted: false)
        case .openSSH, .pkcs8Encrypted:
            throw KeyMaterialError.unreadable(format)
        }
    }

    private static func rsa(format: PrivateKeyFormat, pkcs1: [UInt8]) throws -> KeyMaterial {
        let fields = DERReader.children(ofSequenceIn: pkcs1)
        guard fields.count >= 3, fields[1].tag == DERReader.tagInteger,
            fields[2].tag == DERReader.tagInteger
        else { throw KeyMaterialError.unreadable(format) }

        let modulus = fields[1].contents
        let blob = SSHFingerprint.rsaBlob(exponent: fields[2].contents, modulus: modulus)
        return KeyMaterial(
            format: format,
            algorithm: .rsa,
            isEncrypted: false,
            bitCount: SSHFingerprint.bitCount(ofMagnitude: modulus),
            fingerprint: SSHFingerprint.sha256(ofPublicBlob: blob)
        )
    }

    private static func pkcs8(_ body: [UInt8]) throws -> KeyMaterial {
        let fields = DERReader.children(ofSequenceIn: body)
        guard fields.count >= 3,
            let identifier = fields.first(where: { $0.tag == DERReader.tagSequence }),
            let key = fields.first(where: { $0.tag == DERReader.tagOctetString })
        else { throw KeyMaterialError.unreadable(.pkcs8) }

        var reader = DERReader(identifier.contents)
        let oid = reader.next().map(\.contents) ?? []

        if oid == KeyOID.rsa {
            return try rsa(format: .pkcs8, pkcs1: key.contents)
        }
        guard oid == KeyOID.ed25519, let seed = seed(inOctetString: key.contents),
            let signing = try? Curve25519.Signing.PrivateKey(rawRepresentation: seed)
        else {
            return KeyMaterial(format: .pkcs8, algorithm: .unknown, isEncrypted: false)
        }

        let blob = SSHFingerprint.ed25519Blob(publicKey: signing.publicKey.rawRepresentation)
        return KeyMaterial(
            format: .pkcs8,
            algorithm: .ed25519,
            isEncrypted: false,
            bitCount: 256,
            fingerprint: SSHFingerprint.sha256(ofPublicBlob: blob)
        )
    }

    private static func seed(inOctetString wrapped: [UInt8]) -> [UInt8]? {
        var reader = DERReader(wrapped)
        guard let inner = reader.next(), inner.tag == DERReader.tagOctetString else { return nil }
        return inner.contents
    }

    private static func algorithm(of format: PrivateKeyFormat) -> PrivateKeyAlgorithm {
        switch format {
        case .rsaPKCS1: .rsa
        case .dsaPKCS1: .dsa
        case .ecSEC1: .ecdsa
        case .openSSH, .pkcs8, .pkcs8Encrypted: .unknown
        }
    }

    private enum KeyOID {
        static let rsa: [UInt8] = [0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01]
        static let ed25519: [UInt8] = [0x2B, 0x65, 0x70]
    }
}
