import AnySSHCore
import Foundation

public struct AuthPrivateKey: Sendable, CustomStringConvertible, CustomDebugStringConvertible {
    public let privateKey: Data
    public let publicKey: Data?
    public let passphrase: String?

    public var description: String {
        "AuthPrivateKey(\(privateKey.count) bytes, locked: \(passphrase != nil))"
    }

    public var debugDescription: String {
        description
    }

    public init(privateKey: Data, publicKey: Data? = nil, passphrase: String? = nil) {
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.passphrase = passphrase
    }
}

public enum AuthCredential: Sendable, CustomStringConvertible, CustomDebugStringConvertible {
    case privateKey(AuthPrivateKey)
    case password(String)
    case keyboardInteractive

    public var method: AuthMethod {
        switch self {
        case .privateKey: .publicKey
        case .password: .password
        case .keyboardInteractive: .keyboardInteractive
        }
    }

    public var description: String {
        "AuthCredential(\(method.rawValue))"
    }

    public var debugDescription: String {
        description
    }
}
