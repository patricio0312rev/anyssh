import AnySSHCore
import Foundation
import Testing

@testable import Sessions

@Suite struct SessionRestoreProtectionTests {
    private let directory =
        FileManager.default.temporaryDirectory.appending(
            path: "SessionRestoreProtectionTests-\(UUID().uuidString)")

    @Test func writtenFileIsProtectedAndExcludedFromBackupAndStillRestores() throws {
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = SessionRestoreStore(directory: directory)
        let snapshot = SessionRestoreSnapshot(
            records: [RegistryFixture.record("a", title: "workstation", state: .connected)],
            transcripts: [RegistryFixture.id("a"): ["cat .env", "SECRET=hunter2"]],
            activeSessionID: RegistryFixture.id("a")
        )

        try store.save(snapshot)

        let values = try store.location.resourceValues(
            forKeys: [.isExcludedFromBackupKey, .fileProtectionKey]
        )
        #expect(values.isExcludedFromBackup == true)
        #if os(iOS) && !targetEnvironment(simulator)
        #expect(values.fileProtection == .completeUnlessOpen)
        #endif

        let restored = try #require(try store.load())
        #expect(restored.records.map(\.id) == snapshot.records.map(\.id))
        let original = SessionRestoreTranscript.digest(snapshot.transcripts[RegistryFixture.id("a")] ?? [])
        let reloaded = SessionRestoreTranscript.digest(restored.transcripts[RegistryFixture.id("a")] ?? [])
        #expect(original == reloaded)
    }
}
