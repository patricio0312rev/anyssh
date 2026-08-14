import Foundation
import Security

public enum SecItemAttributes {
    public static let protection = kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String

    public static func query(_ item: KeychainItem) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: item.service,
            kSecAttrAccount as String: item.account,
            kSecAttrSynchronizable as String: false,
        ]
    }

    public static func add(_ item: KeychainItem, secret: Data) throws -> [String: Any] {
        var attributes = query(item)
        attributes[kSecAttrGeneric as String] = KeychainSchema.stamp(item.version)
        attributes[kSecValueData as String] = secret
        switch item.gate {
        case .none:
            attributes[kSecAttrAccessible as String] = protection
        case .biometryCurrentSetOrPasscode:
            attributes[kSecAttrAccessControl as String] = try accessControl()
        }
        return attributes
    }

    public static func read(_ item: KeychainItem) -> [String: Any] {
        var attributes = query(item)
        attributes[kSecReturnData as String] = true
        attributes[kSecMatchLimit as String] = kSecMatchLimitOne
        return attributes
    }

    public static func search(service: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrSynchronizable as String: false,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]
    }

    public static func restamp(to item: KeychainItem) -> [String: Any] {
        [
            kSecAttrAccount as String: item.account,
            kSecAttrGeneric as String: KeychainSchema.stamp(item.version),
        ]
    }

    public static func accessControl() throws -> SecAccessControl {
        var error: Unmanaged<CFError>?
        let control = SecAccessControlCreateWithFlags(
            nil,
            protection as CFString,
            [.biometryCurrentSet, .or, .devicePasscode],
            &error
        )
        error?.release()
        guard let control else { throw KeychainFailure(.accessControl, errSecParam) }
        return control
    }

    public static func item(from attributes: [String: Any], service: String) -> KeychainItem? {
        guard let account = attributes[kSecAttrAccount as String] as? String else { return nil }
        let version = KeychainSchema.version(of: attributes[kSecAttrGeneric as String] as? Data)
        let reference = KeychainSchema.reference(fromAccount: account)
        return KeychainItem(
            service: service,
            account: account,
            version: version,
            gate: reference?.kind.gate ?? .none
        )
    }
}
