import AnySSHCore
import Foundation

public actor InMemorySecretStore: SecretStore {
    public enum Failure: String, CaseIterable, Sendable {
        case writeDenied
        case readDenied
        case biometricCancelled
        case biometricUnavailable

        public var error: SecretStoreError {
            switch self {
            case .writeDenied: .writeDenied
            case .readDenied: .readDenied
            case .biometricCancelled: .biometricCancelled
            case .biometricUnavailable: .biometricUnavailable
            }
        }

        var requiresGate: Bool {
            self == .biometricCancelled || self == .biometricUnavailable
        }
    }

    private var secrets: [SecretReference: Data]
    private var scripted: Failure?

    public init(secrets: [SecretReference: Data] = [:], failure: Failure? = nil) {
        self.secrets = secrets
        self.scripted = failure
    }

    public func script(_ failure: Failure?) {
        scripted = failure
    }

    public func secret(_ reference: SecretReference) async throws -> Data? {
        try refuse(reference, on: [.readDenied, .biometricCancelled, .biometricUnavailable])
        return secrets[reference]
    }

    public func secrets(gated references: [SecretReference]) async throws -> [SecretReference: Data?] {
        var values: [SecretReference: Data?] = [:]
        for reference in references {
            values[reference] = try await secret(reference)
        }
        return values
    }

    public func store(_ secret: Data, at reference: SecretReference) async throws {
        try refuse(reference, on: [.writeDenied])
        secrets[reference] = secret
    }

    public func remove(_ reference: SecretReference) async throws {
        try refuse(reference, on: [.writeDenied])
        secrets[reference] = nil
    }

    private func refuse(_ reference: SecretReference, on applicable: Set<Failure>) throws {
        guard let scripted, applicable.contains(scripted) else { return }
        guard !scripted.requiresGate || reference.kind.gate != .none else { return }
        throw scripted.error
    }
}
