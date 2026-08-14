import AnySSHCore

struct StoppedSessionMuxAdapter: MultiplexerAdapter {
    nonisolated let kind: MultiplexerKind = .herdr
    nonisolated let capabilities: MultiplexerCapabilities = .herdr

    static let runningName = "default"
    static let stoppedName = "anyssh-test"

    let snapshotFailure: ErrorState

    init(snapshotFailure: ErrorState = .command(.failed)) {
        self.snapshotFailure = snapshotFailure
    }

    var running: MuxSession {
        MuxSession(
            id: MuxSessionID(rawValue: Self.runningName),
            name: Self.runningName,
            isAttached: true
        )
    }

    var stopped: MuxSession {
        MuxSession(
            id: MuxSessionID(rawValue: Self.stoppedName),
            name: Self.stoppedName,
            isAttached: false
        )
    }

    func detect() async throws -> MultiplexerInfo {
        MultiplexerInfo(kind: .herdr, binaryPath: "herdr", version: "0.8.0", protocolVersion: 19)
    }

    func listSessions() async throws -> [MuxSession] {
        [running, stopped]
    }

    func snapshot(_ session: MuxSession.ID) async throws -> MuxSnapshot {
        guard session == running.id else { throw snapshotFailure }
        let group = MuxGroup(
            id: MuxGroupID(rawValue: "w1:t1"),
            sessionID: running.id,
            title: "1",
            isActive: true
        )
        return MuxSnapshot(
            session: running,
            groups: [group],
            panes: [
                MuxPane(
                    id: MuxPaneID(rawValue: "w1:p1"),
                    groupID: group.id,
                    title: "w1:p1",
                    workingDirectory: "/Users/dev",
                    isActive: true,
                    agentStatus: "idle",
                    repositoryRoot: nil
                )
            ]
        )
    }

    func readPane(_ pane: MuxPane.ID, lines: Int) async throws -> String { "" }

    func keyBindings() async throws -> MuxKeyBindings {
        MuxKeyBindings(prefix: "ctrl+a", chords: [:])
    }

    func attachCommand(_ target: MuxTarget) -> String {
        MuxAttachCommand.herdr(binary: "herdr", target: target)
    }
}

struct EveryStoppedMuxAdapter: MultiplexerAdapter {
    nonisolated let kind: MultiplexerKind = .herdr
    nonisolated let capabilities: MultiplexerCapabilities = .herdr

    func detect() async throws -> MultiplexerInfo {
        MultiplexerInfo(kind: .herdr, binaryPath: "herdr", version: "0.8.0", protocolVersion: 19)
    }

    func listSessions() async throws -> [MuxSession] {
        [
            MuxSession(id: MuxSessionID(rawValue: "one"), name: "one", isAttached: false),
            MuxSession(id: MuxSessionID(rawValue: "two"), name: "two", isAttached: false),
        ]
    }

    func snapshot(_ session: MuxSession.ID) async throws -> MuxSnapshot {
        throw ErrorState.command(.failed)
    }

    func readPane(_ pane: MuxPane.ID, lines: Int) async throws -> String { "" }

    func keyBindings() async throws -> MuxKeyBindings {
        MuxKeyBindings(prefix: "ctrl+a", chords: [:])
    }

    func attachCommand(_ target: MuxTarget) -> String {
        MuxAttachCommand.herdr(binary: "herdr", target: target)
    }
}
