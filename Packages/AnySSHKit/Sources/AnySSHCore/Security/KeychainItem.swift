import Foundation

public enum KeychainGate: Hashable, Sendable {
    case none
    case biometryCurrentSetOrPasscode
}

public struct KeychainItem: Hashable, Sendable {
    public let service: String
    public let account: String
    public let version: Int
    public let gate: KeychainGate

    public init(service: String, account: String, version: Int, gate: KeychainGate) {
        self.service = service
        self.account = account
        self.version = version
        self.gate = gate
    }

    public static func secret(_ reference: SecretReference) -> KeychainItem {
        KeychainItem(
            service: KeychainSchema.service,
            account: KeychainSchema.account(for: reference),
            version: KeychainSchema.currentVersion,
            gate: reference.kind.gate
        )
    }

    public static let marker = KeychainItem(
        service: KeychainSchema.markerService,
        account: KeychainSchema.markerAccount,
        version: KeychainSchema.currentVersion,
        gate: .none
    )
}

extension SecretKind {
    public var gate: KeychainGate {
        switch self {
        case .password: .none
        case .privateKey, .keyPassphrase: .biometryCurrentSetOrPasscode
        }
    }
}
