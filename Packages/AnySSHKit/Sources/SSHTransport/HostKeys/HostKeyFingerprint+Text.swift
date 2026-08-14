import AnySSHCore
import CryptoKit
import Foundation

extension HostKeyFingerprint {
    public init(_ key: HostKey) {
        self.init(algorithm: key.algorithm, digest: Array(SHA256.hash(data: key.raw)))
    }

    public var openSSH: String {
        let encoded = Data(digest).base64EncodedString()
        return "SHA256:" + encoded.replacing("=", with: "")
    }

    public var hex: String {
        digest.map { String(format: "%02x", $0) }.joined()
    }
}

extension HostKey {
    public var fingerprint: HostKeyFingerprint {
        HostKeyFingerprint(self)
    }

    public func matches(_ other: HostKey) -> Bool {
        algorithm == other.algorithm && raw == other.raw
    }
}
