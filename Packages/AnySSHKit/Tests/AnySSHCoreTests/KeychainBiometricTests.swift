import Foundation
import LocalAuthentication
import Testing

@testable import AnySSHCore

@Suite struct KeychainBiometricTests {
    private func stocked(_ gate: ScriptedGate) async throws -> KeychainSecretStore {
        let store = KeychainSecretStore(backend: FakeKeychain(), authenticator: gate)
        try await store.store(KeychainFixture.keyMaterial, at: KeychainFixture.privateKey)
        return store
    }

    @Test func anAuthenticatedPresentationReleasesTheKey() async throws {
        let gate = ScriptedGate(.authenticated)
        let store = try await stocked(gate)

        #expect(try await store.secret(KeychainFixture.privateKey) == KeychainFixture.keyMaterial)
        #expect(gate.attempts == 1)
    }

    @Test func aResolvedContextNeverSurvivesIntoTheNextGatedRead() async throws {
        let gate = ScriptedGate(.authenticated)
        let store = try await stocked(gate)

        #expect(try await store.secret(KeychainFixture.privateKey) == KeychainFixture.keyMaterial)
        #expect(try await store.secret(KeychainFixture.privateKey) == KeychainFixture.keyMaterial)
        #expect(gate.attempts == 2)
    }

    @Test func cancellingIsItsOwnStateAndNeverAFailure() async throws {
        let gate = ScriptedGate(.cancelled)
        let store = try await stocked(gate)

        await #expect(throws: SecretStoreError.biometricCancelled) {
            try await store.secret(KeychainFixture.privateKey)
        }

        let error = SecretStoreError.biometricCancelled
        #expect(error.stateID == "secrets.biometricCancelled")
        #expect(error != .biometricUnavailable)
        #expect(ErrorState(stateID: error.stateID)?.copy.title == "Authentication cancelled")
        #expect(
            ErrorState(stateID: error.stateID)?.copy.body
                == "The key stays locked until you authenticate. Try again to unlock it."
        )
    }

    @Test func anUnavailableSubsystemAsksForTheKeyAgain() async throws {
        let store = try await stocked(ScriptedGate(.unavailable))

        await #expect(throws: SecretStoreError.biometricUnavailable) {
            try await store.secret(KeychainFixture.privateKey)
        }

        let copy = ErrorState(stateID: SecretStoreError.biometricUnavailable.stateID)?.copy
        #expect(copy?.title == "Biometrics unavailable")
        #expect(copy?.recoveryLabel == "Import Key Again")
    }

    @Test func aChangedEnrolmentInvalidatesTheStoredKey() async throws {
        let backend = FakeKeychain()
        let store = KeychainSecretStore(backend: backend, authenticator: ScriptedGate(.authenticated))
        try await store.store(KeychainFixture.keyMaterial, at: KeychainFixture.privateKey)

        backend.changeEnrolment()

        await #expect(throws: SecretStoreError.biometricUnavailable) {
            try await store.secret(KeychainFixture.privateKey)
        }
    }

    @Test func aRefusedReadOfAnUngatedItemIsNotABiometricState() async throws {
        let backend = FakeKeychain()
        let store = KeychainSecretStore(backend: backend, authenticator: ScriptedGate(.authenticated))
        try await store.store(KeychainFixture.payload("pw"), at: KeychainFixture.password)
        backend.fail(.read, after: 0, status: errSecAuthFailed)

        await #expect(throws: SecretStoreError.readDenied) {
            try await store.secret(KeychainFixture.password)
        }
    }

    @Test func aCancelledSystemPromptDuringAWriteIsNotAWriteRefusal() {
        #expect(SecretStoreError(write: KeychainFailure(.add, errSecUserCanceled)) == .biometricCancelled)
        #expect(SecretStoreError(write: KeychainFailure(.add, errSecIO)) == .writeDenied)
    }

    @Test func aLockedDeviceIsARefusalAndNotACancellation() {
        let failure = KeychainFailure(.read, errSecInteractionNotAllowed)

        #expect(SecretStoreError(read: failure, gate: .biometryCurrentSetOrPasscode) == .readDenied)
        #expect(SecretStoreError(read: failure, gate: .none) == .readDenied)
    }

    @Test(arguments: [
        (LAError.userCancel, BiometricOutcome.cancelled),
        (LAError.appCancel, .cancelled),
        (LAError.systemCancel, .cancelled),
        (LAError.userFallback, .cancelled),
        (LAError.authenticationFailed, .cancelled),
        (LAError.biometryNotAvailable, .unavailable),
        (LAError.biometryNotEnrolled, .unavailable),
        (LAError.biometryLockout, .unavailable),
        (LAError.passcodeNotSet, .unavailable),
        (LAError.invalidContext, .unavailable),
        (LAError.notInteractive, .unavailable),
    ])
    func everyLocalAuthenticationErrorMapsToOneOfTheThreeOutcomes(
        code: LAError.Code,
        expected: BiometricOutcome
    ) {
        let error = NSError(domain: LAError.errorDomain, code: code.rawValue)

        #expect(LocalAuthenticationGate.outcome(for: error) == expected)
    }

    @Test func anUnknownFailureIsTreatedAsUnavailable() {
        #expect(LocalAuthenticationGate.outcome(for: nil) == .unavailable)
        #expect(
            LocalAuthenticationGate.outcome(for: NSError(domain: "other", code: 1)) == .unavailable
        )
    }
}
