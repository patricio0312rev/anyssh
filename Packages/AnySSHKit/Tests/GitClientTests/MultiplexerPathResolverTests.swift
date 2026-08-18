import AnySSHCore
import Testing

@testable import GitClient

@Suite struct MultiplexerPathResolverTests {
    @Test func herdrPrefersTheActivePaneRepositoryRoot() async {
        let adapter = SnapshotAdapter(
            kind: .herdr,
            pane: pane(workingDirectory: "/home/dev/src/api/services", repositoryRoot: "/home/dev/src/api")
        )

        let location = await MultiplexerPathResolver(adapter: adapter, sessionID: Self.session)
            .resolve(Self.record)

        #expect(location?.path == "/home/dev/src/api")
        #expect(location?.provenance == .multiplexer)
    }

    @Test func tmuxUsesTheActivePaneWorkingDirectory() async {
        let adapter = SnapshotAdapter(
            kind: .tmux,
            pane: pane(workingDirectory: "/home/dev/src/api", repositoryRoot: nil)
        )

        let location = await MultiplexerPathResolver(adapter: adapter, sessionID: Self.session)
            .resolve(Self.record)

        #expect(location?.path == "/home/dev/src/api")
        #expect(location?.provenance == .multiplexer)
    }

    @Test func aMissingPaneYieldsNothing() async {
        let adapter = SnapshotAdapter(kind: .herdr, pane: nil)

        let location = await MultiplexerPathResolver(adapter: adapter, sessionID: Self.session)
            .resolve(Self.record)

        #expect(location == nil)
    }

    private static let session = MuxSessionID(rawValue: "default")

    private static let record = SessionRecord(
        id: SessionID(rawValue: "s1"),
        remoteID: RemoteID(rawValue: "r1"),
        connectionID: ConnectionID(rawValue: "c1"),
        title: "build-box",
        state: .connected,
        capabilities: .ssh,
        createdAt: .distantPast,
        lastActiveAt: .distantPast
    )

    private func pane(workingDirectory: String?, repositoryRoot: String?) -> MuxPane {
        MuxPane(
            id: MuxPaneID(rawValue: "p1"),
            groupID: MuxGroupID(rawValue: "g1"),
            title: "agent",
            workingDirectory: workingDirectory,
            isActive: true,
            agentStatus: "working",
            repositoryRoot: repositoryRoot
        )
    }
}

private struct SnapshotAdapter: MultiplexerAdapter {
    let kind: MultiplexerKind
    let capabilities = MultiplexerCapabilities(
        structuredOutput: true,
        agentStatus: true,
        worktreeMetadata: true,
        paneRead: true,
        eventStream: false,
        localSessionSurvival: .unverified,
        remoteBootstrapSurvival: .unverified,
        crossHostSurvival: .unverified
    )
    private let pane: MuxPane?

    init(kind: MultiplexerKind, pane: MuxPane?) {
        self.kind = kind
        self.pane = pane
    }

    func detect() async throws -> MultiplexerInfo {
        MultiplexerInfo(kind: kind, binaryPath: "mux", version: "1", protocolVersion: nil)
    }

    func listSessions() async throws -> [MuxSession] {
        [MuxSession(id: MuxSessionID(rawValue: "default"), name: "default", isAttached: true)]
    }

    func snapshot(_ session: MuxSession.ID) async throws -> MuxSnapshot {
        let mux = MuxSession(id: session, name: "default", isAttached: true)
        let group = MuxGroup(
            id: MuxGroupID(rawValue: "g1"),
            sessionID: session,
            title: "main",
            isActive: true
        )
        return MuxSnapshot(session: mux, groups: [group], panes: pane.map { [$0] } ?? [])
    }

    func readPane(_ pane: MuxPane.ID, lines: Int) async throws -> String { "" }

    func keyBindings() async throws -> MuxKeyBindings {
        MuxKeyBindings(prefix: "", chords: [:])
    }

    func attachCommand(_ target: MuxTarget) -> String { "" }
}
