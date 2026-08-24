import AnySSHCore
import AnySSHMocks

struct SwipeRingMuxAdapter: MultiplexerAdapter {
    nonisolated let kind: MultiplexerKind
    nonisolated let capabilities: MultiplexerCapabilities

    let switchLog = MuxSwitchLog()
    let focusLog = MuxFocusLog()

    private let names: [String]
    private let refusesSwitch: Bool
    private let refusesFocus: Bool
    private let groupTitles: [String]

    init(
        names: [String],
        kind: MultiplexerKind = .tmux,
        refusesSwitch: Bool = false,
        refusesFocus: Bool = false,
        groupTitles: [String] = ["window"]
    ) {
        self.names = names
        self.kind = kind
        self.refusesSwitch = refusesSwitch
        self.refusesFocus = refusesFocus
        self.groupTitles = groupTitles
        capabilities = kind == .herdr ? .herdr : .tmux
    }

    func detect() async throws -> MultiplexerInfo {
        MultiplexerInfo(kind: kind, binaryPath: "mux", version: "1.0", protocolVersion: nil)
    }

    func listSessions() async throws -> [MuxSession] {
        names.map { MuxSession(id: MuxSessionID(rawValue: $0), name: $0, isAttached: false) }
    }

    func snapshot(_ session: MuxSession.ID) async throws -> MuxSnapshot {
        let sessions = try await listSessions()
        guard let match = sessions.first(where: { $0.id == session }) else {
            throw ErrorState.mux(.attachTargetVanished)
        }
        let groups = groupTitles.enumerated().map { index, title in
            MuxGroup(
                id: MuxGroupID(rawValue: "\(session.rawValue):\(title)"),
                sessionID: session,
                title: title,
                isActive: index == 0
            )
        }
        return MuxSnapshot(session: match, groups: groups, panes: [])
    }

    func readPane(_ pane: MuxPane.ID, lines: Int) async throws -> String { "" }

    func keyBindings() async throws -> MuxKeyBindings {
        MuxKeyBindings(prefix: "C-b", chords: [:])
    }

    func focus(_ target: MuxTarget) async throws {
        guard !refusesFocus else { throw ErrorState.mux(.attachTargetVanished) }
        await focusLog.record(target)
    }

    func switchSession(to target: MuxSession.ID, from current: MuxSession.ID) async throws {
        guard !refusesSwitch else { throw ErrorState.mux(.sessionSwitchUnsupported) }
        await switchLog.record(target: target, source: current)
    }

    func attachCommand(_ target: MuxTarget) -> String {
        switch kind {
        case .tmux: MuxAttachCommand.tmux(binary: "tmux", target: target)
        case .herdr: MuxAttachCommand.herdr(binary: "herdr", target: target)
        case .none: ""
        }
    }
}
