import Foundation

public protocol SecretStore: Sendable {
    func secret(_ reference: SecretReference) async throws -> Data?
    func store(_ secret: Data, at reference: SecretReference) async throws
    func remove(_ reference: SecretReference) async throws

    func secrets(gated references: [SecretReference]) async throws -> [SecretReference: Data?]
}

extension SecretStore {
    public func secrets(gated references: [SecretReference]) async throws -> [SecretReference: Data?] {
        var values: [SecretReference: Data?] = [:]
        for reference in references {
            values[reference] = try await secret(reference)
        }
        return values
    }
}
