import Foundation

public protocol KeychainBackend: Sendable {
    func add(_ item: KeychainItem, secret: Data) throws

    func data(for item: KeychainItem, presentation: (any BiometricPresentation)?) throws -> Data?

    func items(inService service: String) throws -> [KeychainItem]

    func restamp(_ item: KeychainItem, to updated: KeychainItem) throws

    func delete(_ item: KeychainItem) throws
}
