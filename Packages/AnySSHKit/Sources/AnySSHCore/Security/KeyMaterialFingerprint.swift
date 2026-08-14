import CryptoKit
import Foundation

enum SSHFingerprint {
    static func sha256(ofPublicBlob blob: [UInt8]) -> String {
        let digest = SHA256.hash(data: Data(blob))
        let encoded = Data(digest).base64EncodedString()
        return "SHA256:" + encoded.replacingOccurrences(of: "=", with: "")
    }

    static func field(_ bytes: some Collection<UInt8>) -> [UInt8] {
        withUnsafeBytes(of: UInt32(bytes.count).bigEndian, Array.init) + Array(bytes)
    }

    static func blob(algorithm: String, fields: [[UInt8]]) -> [UInt8] {
        fields.reduce(into: field(Array(algorithm.utf8))) { $0 += field($1) }
    }

    static func rsaBlob(exponent: some Collection<UInt8>, modulus: some Collection<UInt8>) -> [UInt8] {
        blob(algorithm: "ssh-rsa", fields: [Array(exponent), Array(modulus)])
    }

    static func ed25519Blob(publicKey: some Collection<UInt8>) -> [UInt8] {
        blob(algorithm: "ssh-ed25519", fields: [Array(publicKey)])
    }

    static func bitCount(ofMagnitude magnitude: some Collection<UInt8>) -> Int? {
        let significant = Array(magnitude.drop { $0 == 0 })
        guard let lead = significant.first else { return nil }
        return (significant.count - 1) * 8 + (8 - lead.leadingZeroBitCount)
    }
}
