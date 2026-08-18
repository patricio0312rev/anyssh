import AnySSHCore
import Foundation
import Observation

@MainActor
@Observable
public final class JumpToModel {
    public private(set) var sessions = [JumpSession]()
    public private(set) var isLoading = false
    public private(set) var loadFailed = false
    public private(set) var failureState: ErrorState?
    public private(set) var layout: JumpLayout
    public private(set) var expandedSessionIDs = Set<MuxSessionID>()
    public private(set) var jumpingRowID: MuxGroupID?
    public private(set) var jumpFailure: ErrorState?
    public private(set) var lastOutcome: MuxJumpOutcome?
    public private(set) var lastBytes = [UInt8]()
    public let kind: MultiplexerKind

    private let adapter: (any MultiplexerAdapter)?
    private let navigator: MuxNavigator?
    private let directory: URL?
    private let onBoundSession: ((MuxSessionID) -> Void)?

    public init(
        adapter: any MultiplexerAdapter,
        directory: URL?,
        writer: (any DisplayWriter)?,
        probe: MuxNavigator.AttachmentProbe? = nil,
        onBoundSession: ((MuxSessionID) -> Void)? = nil
    ) {
        self.adapter = adapter
        navigator = writer.map {
            MuxNavigator(adapter: adapter, writer: $0, probe: probe ?? { .unknown })
        }
        self.directory = directory
        self.onBoundSession = onBoundSession
        kind = adapter.kind
        layout = JumpLayoutPreference.load(from: directory)
    }

    public init(
        sessions: [JumpSession],
        kind: MultiplexerKind = .herdr,
        layout: JumpLayout = .list
    ) {
        self.sessions = sessions
        adapter = nil
        navigator = nil
        directory = nil
        onBoundSession = nil
        self.kind = kind
        self.layout = layout
    }

    public var waitingCount: Int {
        sessions.reduce(0) { count, session in
            count + session.groups.filter(\.status.isWaiting).count
        }
    }

    public var showsStatus: Bool { kind == .herdr }

    public var isJumping: Bool { jumpingRowID != nil }

    public var renderedLastBytes: String {
        lastBytes.isEmpty
            ? "[]"
            : "[" + lastBytes.map { String(format: "0x%02x", $0) }.joined(separator: ", ") + "]"
    }

    public func load() async {
        guard let adapter else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let listed = try await adapter.listSessions()
            let collected = await MuxSnapshotLoader.collect(sessions: listed, using: adapter)
            if collected.isEmpty, let failure = collected.failure { throw failure }
            sessions = JumpTreeBuilder.build(
                sessions: listed,
                snapshots: collected.snapshots
            )
            loadFailed = false
            failureState = nil
        } catch {
            loadFailed = true
            failureState = (error as? ErrorState) ?? .mux(.attachTargetVanished)
        }
    }

    public func selectLayout(_ layout: JumpLayout) {
        self.layout = layout
        JumpLayoutPreference.save(layout, to: directory)
    }

    public func toggleExpanded(_ sessionID: MuxSessionID) {
        if expandedSessionIDs.contains(sessionID) {
            expandedSessionIDs.remove(sessionID)
        } else {
            expandedSessionIDs.insert(sessionID)
        }
    }

    public func jump(to row: JumpRow) async -> Bool {
        guard jumpingRowID == nil else { return false }
        jumpingRowID = row.id
        jumpFailure = nil
        lastOutcome = nil
        defer { jumpingRowID = nil }
        guard let navigator else {
            jumpFailure = .mux(.attachTargetVanished)
            return false
        }
        let target = MuxTarget(session: row.sessionID, group: row.group.id)
        do {
            let outcome = try await navigator.jump(to: target)
            lastOutcome = outcome
            lastBytes = outcome == .attached ? navigator.attachBytes(for: target) : []
            switch outcome {
            case .focused, .attached: onBoundSession?(row.sessionID)
            case .focusedElsewhere: break
            }
            return true
        } catch {
            jumpFailure = (error as? ErrorState) ?? .mux(.attachTargetVanished)
            return false
        }
    }
}
