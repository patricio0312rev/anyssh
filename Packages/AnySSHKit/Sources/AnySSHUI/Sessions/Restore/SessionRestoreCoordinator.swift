import AnySSHCore
import Foundation
import Sessions

@MainActor
public final class SessionRestoreCoordinator {
    private let store: SessionRestoreStore
    private weak var source: (any SessionRestoreSource)?
    private var knownIDs: Set<SessionID> = []
    private var lastTranscripts: [SessionID: [String]] = [:]
    private var isWorkspaceVisible = false

    public private(set) var lastSaveError: (any Error)?

    public init(store: SessionRestoreStore) {
        self.store = store
    }

    public func start(source: any SessionRestoreSource) {
        self.source = source
        knownIDs = Set(source.registry.ids)
        isWorkspaceVisible = true
    }

    public func registryDidChange(_ registry: SessionRegistry) {
        let ids = Set(registry.ids)
        let closedSession = ids.count < knownIDs.count
        knownIDs = ids
        if closedSession {
            captureTranscripts()
        }
        persist()
    }

    public func handleBackground() {
        captureTranscripts()
        persist()
    }

    public func noteLeftWorkspace() {
        isWorkspaceVisible = false
        captureTranscripts()
        persist()
    }

    private func captureTranscripts() {
        guard let source else { return }
        var transcripts: [SessionID: [String]] = [:]
        for record in source.registry.sessions {
            guard let dump = source.screenDump(for: record.id) else { continue }
            transcripts[record.id] = SessionRestoreTranscript.tail(
                of: dump,
                maxLines: SessionRestorePolicy.persistedTailLines
            )
        }
        lastTranscripts = transcripts
    }

    private func persist() {
        guard let source else { return }
        do {
            try store.save(
                SessionRestoreSnapshot(
                    records: source.registry.sessions,
                    transcripts: lastTranscripts,
                    activeSessionID: isWorkspaceVisible ? source.activeSessionID : nil
                )
            )
            lastSaveError = nil
        } catch {
            lastSaveError = error
        }
    }
}
