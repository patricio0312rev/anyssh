import Foundation
import Testing

@testable import AnySSHCore

@Suite struct KeychainRoundTripTests {
    private func store(_ backend: FakeKeychain, _ gate: ScriptedGate) -> KeychainSecretStore {
        KeychainSecretStore(backend: backend, authenticator: gate)
    }

    @Test func aThreeKilobyteKeySurvivesTheRoundTripByteForByte() async throws {
        let backend = FakeKeychain()
        let gate = ScriptedGate(.authenticated)
        let store = store(backend, gate)

        #expect(KeychainFixture.keyMaterial.count == KeychainFixture.keyLength)
        try await store.store(KeychainFixture.keyMaterial, at: KeychainFixture.privateKey)
        let read = try await store.secret(KeychainFixture.privateKey)

        #expect(read == KeychainFixture.keyMaterial)
        #expect(read?.count == KeychainFixture.keyLength)
        #expect(gate.attempts == 1)
        #expect(backend.presentedReads == 1)
    }

    @Test func aDeletedSecretReadsAsAbsent() async throws {
        let backend = FakeKeychain()
        let store = store(backend, ScriptedGate(.authenticated))

        try await store.store(KeychainFixture.keyMaterial, at: KeychainFixture.privateKey)
        try await store.remove(KeychainFixture.privateKey)

        #expect(try await store.secret(KeychainFixture.privateKey) == nil)
        #expect(backend.stored.isEmpty)
    }

    @Test func aMissingGatedSecretIsAnsweredWithoutAPrompt() async throws {
        let gate = ScriptedGate(.authenticated)
        let store = store(FakeKeychain(), gate)

        #expect(try await store.secret(KeychainFixture.privateKey) == nil)
        #expect(gate.attempts == 0)
    }

    @Test func removingASecretThatIsNotThereSucceeds() async throws {
        let store = store(FakeKeychain(), ScriptedGate(.authenticated))

        try await store.remove(KeychainFixture.privateKey)
    }

    @Test func storingTwiceReplacesRatherThanDuplicates() async throws {
        let backend = FakeKeychain()
        let store = store(backend, ScriptedGate(.authenticated))
        let replacement = Data("second".utf8)

        try await store.store(KeychainFixture.keyMaterial, at: KeychainFixture.privateKey)
        try await store.store(replacement, at: KeychainFixture.privateKey)

        #expect(backend.stored.count == 1)
        #expect(try await store.secret(KeychainFixture.privateKey) == replacement)
    }

    @Test func aPasswordIsReadWithoutAPresentation() async throws {
        let backend = FakeKeychain()
        let gate = ScriptedGate(.authenticated)
        let store = store(backend, gate)
        let payload = KeychainFixture.payload("password")

        try await store.store(payload, at: KeychainFixture.password)

        #expect(try await store.secret(KeychainFixture.password) == payload)
        #expect(gate.attempts == 0)
        #expect(backend.presentedReads == 0)
    }

    @Test func aGatedReadWithoutAPresentationIsRefused() async throws {
        let store = store(FakeKeychain(), ScriptedGate(.authenticated, presents: false))

        try await store.store(KeychainFixture.keyMaterial, at: KeychainFixture.privateKey)

        await #expect(throws: SecretStoreError.readDenied) {
            try await store.secret(KeychainFixture.privateKey)
        }
    }

    @Test func everyKindRoundTripsUnderItsOwnAccount() async throws {
        let backend = FakeKeychain()
        let store = store(backend, ScriptedGate(.authenticated))

        for kind in SecretKind.allCases {
            let reference = SecretReference(remoteID: KeychainFixture.remote, kind: kind)
            try await store.store(KeychainFixture.payload(kind.rawValue), at: reference)
        }

        for kind in SecretKind.allCases {
            let reference = SecretReference(remoteID: KeychainFixture.remote, kind: kind)
            #expect(try await store.secret(reference) == KeychainFixture.payload(kind.rawValue))
        }
        #expect(backend.stored.count == SecretKind.allCases.count)
    }

    @Test(.enabled(if: LiveKeychain.isReachable))
    func theLiveBackendRoundTripsAnUngatedItem() throws {
        let backend = SecItemKeychain(dataProtection: false)
        let item = KeychainItem(
            service: LiveKeychain.service,
            account: "round-trip",
            version: KeychainSchema.currentVersion,
            gate: .none
        )
        defer { try? backend.delete(item) }

        try backend.delete(item)
        try backend.add(item, secret: KeychainFixture.keyMaterial)

        #expect(try backend.data(for: item, presentation: nil) == KeychainFixture.keyMaterial)
        #expect(try backend.items(inService: item.service).map(\.account) == ["round-trip"])
        #expect(try backend.items(inService: item.service).map(\.version) == [1])

        try backend.delete(item)
        #expect(try backend.data(for: item, presentation: nil) == nil)
    }
}
