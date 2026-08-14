import AnySSHCore
import Observation

@MainActor
@Observable
public final class MultiplexerPaneListModel {
    public private(set) var sessions = [MuxSession]()
    public private(set) var snapshots = [MuxSessionID: MuxSnapshot]()
    public private(set) var isLoading = false
    public private(set) var failureState: ErrorState?

    private let adapter: any MultiplexerAdapter

    public init(adapter: any MultiplexerAdapter) {
        self.adapter = adapter
    }

    public func load() async {
        guard adapter.kind != .none else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let listed = try await adapter.listSessions()
            var loaded = [MuxSessionID: MuxSnapshot]()
            for session in listed {
                loaded[session.id] = try await adapter.snapshot(session.id)
            }
            sessions = listed
            snapshots = loaded
            failureState = nil
        } catch {
            failureState = (error as? ErrorState) ?? .mux(.attachTargetVanished)
        }
    }

    public func snapshot(for session: MuxSessionID) -> MuxSnapshot? {
        snapshots[session]
    }

    public func attachCommand(for session: MuxSessionID) -> String {
        adapter.attachCommand(MuxTarget(session: session))
    }
}
