import Foundation
import Security
import Testing

@testable import AnySSHCore

@Suite struct KeychainSecrecyTests {
    private static let fragments: [String] = [
        KeychainFixture.token,
        String(decoding: KeychainFixture.keyMaterial.prefix(96), as: UTF8.self),
        "BEGIN OPENSSH PRIVATE KEY",
    ]

    private func expectClean(_ rendered: String, _ label: Comment) {
        for fragment in Self.fragments {
            #expect(!rendered.contains(fragment), label)
        }
    }

    private func renderings(of value: some Any) -> String {
        "\(String(describing: value))\n\(String(reflecting: value))"
    }

    @Test func noErrorTheStoreThrowsCanCarryASecret() async throws {
        for error in [
            SecretStoreError.writeDenied, .readDenied, .biometricCancelled, .biometricUnavailable,
            .migrationFailed,
        ] {
            expectClean(renderings(of: error), "SecretStoreError")
            expectClean(error.localizedDescription, "localizedDescription")
            expectClean(error.stateID, "stateID")
        }
    }

    @Test func noKeychainFailureCanCarryASecret() {
        for operation in [
            KeychainFailure.Operation.add, .read, .search, .update, .delete, .accessControl,
        ] {
            expectClean(renderings(of: KeychainFailure(operation, errSecAuthFailed)), "KeychainFailure")
        }
    }

    @Test func noItemOrReferenceCanCarryASecret() {
        expectClean(renderings(of: KeychainItem.secret(KeychainFixture.privateKey)), "KeychainItem")
        expectClean(renderings(of: KeychainFixture.privateKey), "SecretReference")
        expectClean(renderings(of: KeychainItem.marker), "marker")
        expectClean(KeychainSecretStore.defaultReason, "prompt reason")
    }

    @Test func theAddDictionaryHoldsTheSecretUnderOneKeyOnly() throws {
        let item = KeychainItem.secret(KeychainFixture.privateKey)
        var attributes = try SecItemAttributes.add(item, secret: KeychainFixture.keyMaterial)

        #expect(attributes[kSecValueData as String] as? Data == KeychainFixture.keyMaterial)
        attributes[kSecValueData as String] = nil

        expectClean(renderings(of: attributes), "add attributes")
    }

    @Test func enumeratingAStoreNeverSurfacesAPayload() async throws {
        let backend = FakeKeychain()
        let store = KeychainSecretStore(backend: backend, authenticator: ScriptedGate(.authenticated))
        try await store.store(KeychainFixture.keyMaterial, at: KeychainFixture.privateKey)

        let items = try backend.items(inService: KeychainSchema.service)

        #expect(items.count == 1)
        expectClean(renderings(of: items), "enumerated items")
        expectClean(renderings(of: backend.stored), "stored items")
    }

    @Test func aMigrationNeverReadsTheSecretItMoves() throws {
        let backend = FakeKeychain(
            seeded: [(KeychainFixture.legacyItem("alpha"), KeychainFixture.keyMaterial)]
        )

        try KeychainMigrator(backend: backend).run()

        #expect(backend.counts.updates == 1)
        #expect(backend.presentedReads == 0)
        #expect(
            backend.payload(service: KeychainSchema.service, account: "privateKey.alpha")
                == KeychainFixture.keyMaterial
        )
    }

    @Test func theRegistryCopyForEverySecretsStateIsStatic() {
        for state in SecretsErrorState.allCases {
            expectClean(renderings(of: state.copy), "registry copy")
        }
    }

    @Test func aFailedGatedReadSaysNothingAboutWhatItGuards() async throws {
        let backend = FakeKeychain()
        let store = KeychainSecretStore(backend: backend, authenticator: ScriptedGate(.cancelled))
        try await store.store(KeychainFixture.keyMaterial, at: KeychainFixture.privateKey)

        do {
            _ = try await store.secret(KeychainFixture.privateKey)
            Issue.record("the gated read should have been refused")
        } catch {
            expectClean(renderings(of: error), "thrown error")
            expectClean(error.localizedDescription, "thrown localizedDescription")
        }
    }
}
