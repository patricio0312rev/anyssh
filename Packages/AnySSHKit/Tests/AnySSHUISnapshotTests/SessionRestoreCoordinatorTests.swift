import AnySSHCore
import AnySSHMocks
import Foundation
import Sessions
import Testing

@testable import AnySSHUI

@MainActor
private final class RestoreSourceStub: SessionRestoreSource {
    var registry: SessionRegistry
    var activeSessionID: SessionID?
    var dumps: [SessionID: String]
    private(set) var dumpReads = 0

    init(records: [SessionRecord]) {
        registry = SessionRegistry(records)
        activeSessionID = records.first?.id
        dumps = Dictionary(
            uniqueKeysWithValues: records.map { ($0.id, "line one\nline two\nline three\n") }
        )
    }

    func screenDump(for id: SessionID) -> String? {
        dumpReads += 1
        return dumps[id]
    }
}

@Suite @MainActor struct SessionRestoreCoordinatorTests {
    @Test func aRegistryChangeWritesRecordsWithoutTouchingTranscripts() throws {
        let (store, coordinator, source) = make()
        defer { try? store.clear() }

        coordinator.start(source: source)
        coordinator.registryDidChange(source.registry)

        let snapshot = try #require(try store.load())
        #expect(snapshot.records.map(\.id) == source.registry.ids)
        #expect(snapshot.transcripts.isEmpty)
        #expect(source.dumpReads == 0)
    }

    @Test func closingASessionCapturesTheTranscriptTail() throws {
        let (store, coordinator, source) = make()
        defer { try? store.clear() }

        coordinator.start(source: source)
        let closed = try #require(source.registry.ids.last)
        _ = source.registry.close(closed)
        coordinator.registryDidChange(source.registry)

        let snapshot = try #require(try store.load())
        #expect(snapshot.transcripts.count == source.registry.count)
        #expect(snapshot.transcripts[source.registry.ids[0]] == ["line one", "line two", "line three"])
    }

    @Test func backgroundingWritesTheTranscriptAndKeepsTheActiveSession() throws {
        let (store, coordinator, source) = make()
        defer { try? store.clear() }

        coordinator.start(source: source)
        coordinator.handleBackground()

        let snapshot = try #require(try store.load())
        #expect(snapshot.activeSessionID == source.activeSessionID)
        #expect(snapshot.transcripts.count == source.registry.count)
    }

    @Test func leavingTheWorkspaceClearsTheActiveSessionButKeepsTheSessions() throws {
        let (store, coordinator, source) = make()
        defer { try? store.clear() }

        coordinator.start(source: source)
        coordinator.noteLeftWorkspace()

        let snapshot = try #require(try store.load())
        #expect(snapshot.activeSessionID == nil)
        #expect(snapshot.records.count == source.registry.count)
    }

    @Test func aWriteFailureIsRecordedRatherThanThrown() {
        let store = SessionRestoreStore(
            fileURL: URL(filePath: "/dev/null/anyssh/session-restore.json")
        )
        let coordinator = SessionRestoreCoordinator(store: store)
        let source = RestoreSourceStub(records: SessionScenario.records("single"))

        coordinator.start(source: source)
        coordinator.handleBackground()

        #expect(coordinator.lastSaveError != nil)
    }

    private func make() -> (SessionRestoreStore, SessionRestoreCoordinator, RestoreSourceStub) {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "anyssh-restore-\(UUID().uuidString)")
        let store = SessionRestoreStore(directory: directory)
        return (
            store,
            SessionRestoreCoordinator(store: store),
            RestoreSourceStub(records: SessionScenario.records("four"))
        )
    }
}
