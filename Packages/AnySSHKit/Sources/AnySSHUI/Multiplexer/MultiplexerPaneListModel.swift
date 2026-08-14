import AnySSHCore
import Observation

@MainActor
@Observable
public final class MultiplexerPaneListModel {
    public private(set) var sessions = [MuxSession]()
    public private(set) var snapshots = [MuxSessionID: MuxSnapshot]()
    public private(set) var isLoading = false
    public private(set) var failureState: ErrorState?
    public private(set) var attachingPaneID: MuxPaneID?
    public private(set) var attachFailure: ErrorState?

    private let adapter: any MultiplexerAdapter
    private let writer: (any DisplayWriter)?

    public init(adapter: any MultiplexerAdapter, writer: (any DisplayWriter)? = nil) {
        self.adapter = adapter
        self.writer = writer
    }

    public var isAttaching: Bool { attachingPaneID != nil }

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

    public func attach(to session: MuxSessionID, from pane: MuxPaneID) async -> Bool {
        guard attachingPaneID == nil else { return false }
        attachingPaneID = pane
        attachFailure = nil
        defer { attachingPaneID = nil }
        let command = adapter.attachCommand(MuxTarget(session: session))
        guard !command.isEmpty, let writer else {
            attachFailure = .mux(.attachTargetVanished)
            return false
        }
        do {
            try await writer.send(Array((command + "\r").utf8)[...])
            return true
        } catch {
            attachFailure = (error as? ErrorState) ?? .mux(.attachTargetVanished)
            return false
        }
    }
}
