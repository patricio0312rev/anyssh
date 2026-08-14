import AnySSHCore

struct MuxSnapshotCollection: Sendable {
    let snapshots: [MuxSessionID: MuxSnapshot]
    let failure: ErrorState?

    var isEmpty: Bool { snapshots.isEmpty }
}

enum MuxSnapshotLoader {
    static func collect(
        sessions: [MuxSession],
        using adapter: any MultiplexerAdapter
    ) async -> MuxSnapshotCollection {
        var snapshots = [MuxSessionID: MuxSnapshot]()
        var failure: ErrorState?
        for session in sessions {
            do {
                snapshots[session.id] = try await adapter.snapshot(session.id)
            } catch {
                failure = (error as? ErrorState) ?? .mux(.attachTargetVanished)
            }
        }
        return MuxSnapshotCollection(snapshots: snapshots, failure: failure)
    }
}
