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
    public private(set) var lastOutcome: MuxJumpOutcome?

    private let adapter: any MultiplexerAdapter
    private let navigator: MuxNavigator?
    private let onBoundSession: ((MuxSessionID) -> Void)?

    public init(
        adapter: any MultiplexerAdapter,
        writer: (any DisplayWriter)? = nil,
        probe: MuxNavigator.AttachmentProbe? = nil,
        onBoundSession: ((MuxSessionID) -> Void)? = nil
    ) {
        self.adapter = adapter
        navigator = writer.map {
            MuxNavigator(adapter: adapter, writer: $0, probe: probe ?? { .unknown })
        }
        self.onBoundSession = onBoundSession
    }

    public var isAttaching: Bool { attachingPaneID != nil }

    public func load() async {
        guard adapter.kind != .none else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let listed = try await adapter.listSessions()
            let collected = await MuxSnapshotLoader.collect(sessions: listed, using: adapter)
            if collected.isEmpty, let failure = collected.failure { throw failure }
            sessions = listed.filter { collected.snapshots[$0.id] != nil }
            snapshots = collected.snapshots
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
        lastOutcome = nil
        defer { attachingPaneID = nil }
        guard let navigator else {
            attachFailure = .mux(.attachTargetVanished)
            return false
        }
        do {
            let outcome = try await navigator.jump(to: MuxTarget(session: session, pane: pane))
            lastOutcome = outcome
            switch outcome {
            case .focused, .attached: onBoundSession?(session)
            case .focusedElsewhere: break
            }
            return true
        } catch {
            attachFailure = (error as? ErrorState) ?? .mux(.attachTargetVanished)
            return false
        }
    }
}
