import Foundation

public actor KeychainSecretStore: SecretStore {
    public static let defaultReason = "Unlock your stored key to connect"

    private let backend: any KeychainBackend
    private let authenticator: any BiometricAuthenticator
    private let reason: String
    private var openPresentation: (any BiometricPresentation)?
    private var presentationReadsLeft = 0

    public init(
        backend: any KeychainBackend = SecItemKeychain(),
        authenticator: any BiometricAuthenticator = LocalAuthenticationGate(),
        reason: String = defaultReason
    ) {
        self.backend = backend
        self.authenticator = authenticator
        self.reason = reason
    }

    public func secret(_ reference: SecretReference) async throws -> Data? {
        let values = try await secrets(gated: [reference])
        return values[reference] ?? nil
    }

    public func secrets(gated references: [SecretReference]) async throws -> [SecretReference: Data?] {
        var values: [SecretReference: Data?] = [:]
        var gatedExisting: [SecretReference] = []

        for reference in references {
            let item = KeychainItem.secret(reference)
            if item.gate == .none {
                values[reference] = try read(item, presentation: nil)
                continue
            }
            if try exists(item) {
                gatedExisting.append(reference)
            } else {
                values[reference] = nil
            }
        }

        guard !gatedExisting.isEmpty else { return values }

        let presentation = try await presentationForGatedRead(count: gatedExisting.count)
        defer { clearPresentation() }
        for reference in gatedExisting {
            values[reference] = try read(
                KeychainItem.secret(reference),
                presentation: presentation
            )
        }
        return values
    }

    public func store(_ secret: Data, at reference: SecretReference) async throws {
        clearPresentation()
        let item = KeychainItem.secret(reference)
        do {
            try backend.delete(item)
            try backend.add(item, secret: secret)
        } catch let failure as KeychainFailure {
            throw SecretStoreError(write: failure)
        }
    }

    public func remove(_ reference: SecretReference) async throws {
        clearPresentation()
        do {
            try backend.delete(KeychainItem.secret(reference))
        } catch let failure as KeychainFailure {
            throw SecretStoreError(write: failure)
        }
    }

    private func exists(_ item: KeychainItem) throws -> Bool {
        do {
            return try backend.items(inService: item.service).contains { $0.account == item.account }
        } catch let failure as KeychainFailure {
            throw SecretStoreError(read: failure, gate: item.gate)
        }
    }

    private func presentationForGatedRead(count: Int) async throws -> (any BiometricPresentation)? {
        let result = await authenticator.authenticate(reason: reason)
        switch result.outcome {
        case .authenticated:
            openPresentation = result.presentation
            presentationReadsLeft = count
            return result.presentation
        case .cancelled:
            clearPresentation()
            throw SecretStoreError.biometricCancelled
        case .unavailable:
            clearPresentation()
            throw SecretStoreError.biometricUnavailable
        }
    }

    private func read(_ item: KeychainItem, presentation: (any BiometricPresentation)?) throws -> Data? {
        do {
            let data = try backend.data(for: item, presentation: presentation)
            if presentation != nil {
                presentationReadsLeft -= 1
                if presentationReadsLeft <= 0 { clearPresentation() }
            }
            return data
        } catch let failure as KeychainFailure {
            clearPresentation()
            throw SecretStoreError(read: failure, gate: item.gate)
        }
    }

    private func clearPresentation() {
        openPresentation?.invalidate()
        openPresentation = nil
        presentationReadsLeft = 0
    }
}
