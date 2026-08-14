import Foundation

public struct KeychainMigrator: Sendable {
    public static let shipped: [any KeychainMigration] = [StampedAccountMigration()]

    private let backend: any KeychainBackend
    private let migrations: [any KeychainMigration]

    public init(
        backend: any KeychainBackend,
        migrations: [any KeychainMigration] = KeychainMigrator.shipped
    ) {
        self.backend = backend
        self.migrations = migrations.sorted { $0.producedVersion < $1.producedVersion }
    }

    public func storedVersion() throws -> Int {
        do {
            let stamp = try backend.data(for: KeychainItem.marker, presentation: nil)
            return KeychainSchema.version(of: stamp)
        } catch {
            throw SecretStoreError.migrationFailed
        }
    }

    public var targetVersion: Int {
        migrations.last?.producedVersion ?? KeychainSchema.unversioned
    }

    @discardableResult
    public func run() throws -> Int {
        let current = try storedVersion()
        guard current < targetVersion else { return current }

        for migration in migrations where migration.producedVersion > current {
            do {
                try migration.apply(to: backend)
            } catch {
                throw SecretStoreError.migrationFailed
            }
        }
        try record(targetVersion)
        return targetVersion
    }

    private func record(_ version: Int) throws {
        do {
            try backend.delete(KeychainItem.marker)
            try backend.add(KeychainItem.marker, secret: KeychainSchema.stamp(version))
        } catch {
            throw SecretStoreError.migrationFailed
        }
    }
}
