import Foundation

public protocol KeychainMigration: Sendable {
    var producedVersion: Int { get }

    func apply(to backend: any KeychainBackend) throws
}

public struct StampedAccountMigration: KeychainMigration {
    public let producedVersion = 1

    public let legacyKind: SecretKind

    public init(legacyKind: SecretKind = .privateKey) {
        self.legacyKind = legacyKind
    }

    public func apply(to backend: any KeychainBackend) throws {
        for item in try backend.items(inService: KeychainSchema.service)
        where item.version < producedVersion {
            try backend.restamp(item, to: KeychainItem.secret(reference(for: item)))
        }
    }

    private func reference(for item: KeychainItem) -> SecretReference {
        KeychainSchema.reference(fromAccount: item.account)
            ?? SecretReference(remoteID: RemoteID(rawValue: item.account), kind: legacyKind)
    }
}
