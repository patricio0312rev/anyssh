import Foundation
import Testing

@testable import AnySSHCore

@Suite struct KeychainMigrationTests {
    private static let legacy = ["alpha", "beta", "gamma"]

    private func seeded() -> FakeKeychain {
        FakeKeychain(
            seeded: Self.legacy.map { (KeychainFixture.legacyItem($0), KeychainFixture.payload($0)) }
        )
    }

    private func migrator(_ backend: FakeKeychain) -> KeychainMigrator {
        KeychainMigrator(backend: backend)
    }

    @Test func anUnmigratedStoreReportsTheUnversionedShape() throws {
        #expect(try migrator(seeded()).storedVersion() == KeychainSchema.unversioned)
    }

    @Test func theMigratorStampsEveryItemAndRecordsTheVersion() throws {
        let backend = seeded()

        #expect(try migrator(backend).run() == 1)

        #expect(try migrator(backend).storedVersion() == 1)
        #expect(
            backend.stored.filter { $0.service == KeychainSchema.service }.map(\.account) == [
                "privateKey.alpha", "privateKey.beta", "privateKey.gamma",
            ])
        #expect(backend.stored.allSatisfy { $0.version == 1 })
    }

    @Test func aMigratedSecretIsStillReadableAndUnchanged() async throws {
        let backend = seeded()
        try migrator(backend).run()

        let store = KeychainSecretStore(backend: backend, authenticator: ScriptedGate(.authenticated))
        let reference = SecretReference(remoteID: RemoteID(rawValue: "beta"), kind: .privateKey)

        #expect(try await store.secret(reference) == KeychainFixture.payload("beta"))
    }

    @Test func aSecondRunChangesNothing() throws {
        let backend = seeded()
        try migrator(backend).run()
        let after = backend.counts

        #expect(try migrator(backend).run() == 1)

        #expect(backend.counts.adds == after.adds)
        #expect(backend.counts.updates == after.updates)
        #expect(backend.counts.deletes == after.deletes)
        #expect(backend.counts.searches == after.searches)
        #expect(backend.stored.count == Self.legacy.count + 1)
    }

    @Test func anInterruptedRunLosesNothingAndCompletesOnTheNextTry() throws {
        let backend = seeded()
        backend.fail(.update, after: 1)

        #expect(throws: SecretStoreError.migrationFailed) { try migrator(backend).run() }

        #expect(try migrator(backend).storedVersion() == KeychainSchema.unversioned)
        #expect(backend.stored.count == Self.legacy.count)
        #expect(
            backend.payload(service: KeychainSchema.service, account: "privateKey.alpha")
                == KeychainFixture.payload("alpha"))
        #expect(
            backend.payload(service: KeychainSchema.service, account: "beta")
                == KeychainFixture.payload("beta"))

        backend.clearFailures()
        #expect(try migrator(backend).run() == 1)

        for remote in Self.legacy {
            #expect(
                backend.payload(service: KeychainSchema.service, account: "privateKey.\(remote)")
                    == KeychainFixture.payload(remote))
        }
    }

    @Test func aStepAppliedToAHalfStampedStoreIsIdempotent() throws {
        let backend = seeded()
        let step = StampedAccountMigration()

        try step.apply(to: backend)
        try step.apply(to: backend)

        #expect(
            backend.stored.map(\.account) == [
                "privateKey.alpha", "privateKey.beta", "privateKey.gamma",
            ])
        #expect(backend.stored.allSatisfy { $0.version == 1 })
    }

    @Test func anAccountThatAlreadyParsesIsOnlyStamped() throws {
        let account = "privateKey.delta"
        let backend = FakeKeychain(
            seeded: [(KeychainFixture.legacyItem(account), KeychainFixture.payload("delta"))]
        )

        try migrator(backend).run()

        #expect(
            backend.stored.filter { $0.service == KeychainSchema.service }.map(\.account)
                == [account])
        #expect(
            backend.payload(service: KeychainSchema.service, account: account)
                == KeychainFixture.payload("delta"))
    }

    @Test func aStoreFromTheFutureIsLeftAlone() throws {
        let backend = seeded()
        try backend.add(KeychainItem.marker, secret: KeychainSchema.stamp(9))
        let before = backend.stored

        #expect(try migrator(backend).run() == 9)

        #expect(backend.stored == before)
    }

    @Test func aRunWithNoStepsIsANoOp() throws {
        let backend = seeded()

        #expect(
            try KeychainMigrator(backend: backend, migrations: []).run()
                == KeychainSchema.unversioned)
        #expect(backend.counts.updates == 0)
    }

    @Test func theShippedListStartsAtVersionOne() {
        #expect(KeychainMigrator.shipped.map(\.producedVersion) == [1])
        #expect(KeychainMigrator(backend: FakeKeychain()).targetVersion == KeychainSchema.currentVersion)
    }
}
