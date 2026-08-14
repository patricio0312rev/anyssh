import Foundation
import Security

public struct SecItemKeychain: KeychainBackend {
    private let dataProtection: Bool

    public init(dataProtection: Bool = true) {
        self.dataProtection = dataProtection
    }

    public func add(_ item: KeychainItem, secret: Data) throws {
        let status = SecItemAdd(scoped(try SecItemAttributes.add(item, secret: secret)), nil)
        guard status == errSecSuccess else { throw KeychainFailure(.add, status) }
    }

    public func data(
        for item: KeychainItem,
        presentation: (any BiometricPresentation)?
    ) throws -> Data? {
        var query = SecItemAttributes.read(item)
        presentation?.apply(to: &query)
        var result: CFTypeRef?
        let status = SecItemCopyMatching(scoped(query), &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainFailure(.read, status) }
        return result as? Data
    }

    public func items(inService service: String) throws -> [KeychainItem] {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(scoped(SecItemAttributes.search(service: service)), &result)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess else { throw KeychainFailure(.search, status) }
        guard let found = result as? [[String: Any]] else { return [] }
        return found.compactMap { SecItemAttributes.item(from: $0, service: service) }
    }

    public func restamp(_ item: KeychainItem, to updated: KeychainItem) throws {
        let status = SecItemUpdate(
            scoped(SecItemAttributes.query(item)),
            SecItemAttributes.restamp(to: updated) as CFDictionary
        )
        guard status == errSecSuccess else { throw KeychainFailure(.update, status) }
    }

    public func delete(_ item: KeychainItem) throws {
        let status = SecItemDelete(scoped(SecItemAttributes.query(item)))
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainFailure(.delete, status)
        }
    }

    private func scoped(_ attributes: [String: Any]) -> CFDictionary {
        var scoped = attributes
        if dataProtection {
            scoped[kSecUseDataProtectionKeychain as String] = true
        }
        return scoped as CFDictionary
    }
}
