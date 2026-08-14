import AnySSHCore
import Foundation
import Testing

@testable import Sessions

@Suite struct SessionRestoreTests {
    private let directory =
        FileManager.default.temporaryDirectory.appending(path: "SessionRestoreTests-\(UUID().uuidString)")

    @Test func fourRecordsRoundTripThroughAFreshStoreOverTheSameDirectory() throws {
        defer { try? FileManager.default.removeItem(at: directory) }

        let records = [
            RegistryFixture.record("a", title: "workstation", state: .connected, idle: 10),
            RegistryFixture.record("b", remote: "build-box", title: "ci@build-box", state: .connected),
            RegistryFixture.record(
                "c", remote: "edge-node", title: "root@edge-node", state: .reconnecting(attempt: 2)),
            RegistryFixture.record("d", title: "workstation-2", state: .disconnected(.closedByUser), idle: 4),
        ]
        let transcripts: [SessionID: [String]] = [
            RegistryFixture.id("a"): ["prompt a", "echo one"],
            RegistryFixture.id("b"): ["prompt b", "echo two", "echo three"],
            RegistryFixture.id("c"): ["prompt c"],
            RegistryFixture.id("d"): [],
        ]
        let snapshot = SessionRestoreSnapshot(
            records: records,
            transcripts: transcripts,
            activeSessionID: RegistryFixture.id("b")
        )

        let first = SessionRestoreStore(directory: directory)
        try first.save(snapshot)

        let second = SessionRestoreStore(directory: directory)
        let restored = try #require(try second.load())

        #expect(restored.records.map(\.id) == records.map(\.id))
        #expect(restored.records.map(\.title) == records.map(\.title))
        #expect(restored.records.map(\.remoteID) == records.map(\.remoteID))
        #expect(restored.activeSessionID == RegistryFixture.id("b"))

        for id in restored.transcripts.keys {
            let original = SessionRestoreTranscript.digest(transcripts[id] ?? [])
            let reloaded = SessionRestoreTranscript.digest(restored.transcripts[id] ?? [])
            #expect(original == reloaded, "transcript for \(id.rawValue) changed checksum")
        }
    }

    @Test func restoredRecordsAreAlwaysDisconnected() throws {
        defer { try? FileManager.default.removeItem(at: directory) }

        let records = [
            RegistryFixture.record("a", state: .connected),
            RegistryFixture.record("b", state: .connecting),
            RegistryFixture.record("c", state: .reconnecting(attempt: 1)),
            RegistryFixture.record("d", state: .disconnected(.failed(stateID: "transport.keepaliveTimeout"))),
        ]
        try SessionRestoreStore(directory: directory).save(
            SessionRestoreSnapshot(records: records, transcripts: [:], activeSessionID: nil)
        )

        let restored = try #require(try SessionRestoreStore(directory: directory).load())

        #expect(restored.records.allSatisfy { !Self.isConnected($0) })
        #expect(restored.records.allSatisfy { Self.isBackgrounded($0) })
    }

    @Test func aNewerSchemaIsRefusedWhole() throws {
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = directory.appending(path: SessionRestorePolicy.fileName)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let envelope = #"{"schemaVersion": 99, "records": [], "transcripts": [], "activeSessionID": null}"#
        try Data(envelope.utf8).write(to: url)

        #expect(throws: SessionRestoreError.unsupportedSchemaVersion(99)) {
            _ = try SessionRestoreStore(directory: directory).load()
        }
    }

    private static func isConnected(_ record: SessionRecord) -> Bool {
        record.state == .connected
    }

    private static func isBackgrounded(_ record: SessionRecord) -> Bool {
        record.state == .disconnected(.backgrounded)
    }
}
