import AnySSHCore
import Foundation
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

    @Test func herdrWithoutAWorktreeAsksGitForTheRepositoryRoot() async {
        let adapter = SnapshotAdapter(
            kind: .herdr,
            pane: pane(workingDirectory: "/home/dev/src/api/services", repositoryRoot: nil)
        )
        let runner = RootRunner(output: "/home/dev/src/api\n", exitCode: 0)

        let location = await MultiplexerPathResolver(
            adapter: adapter,
            sessionID: Self.session,
            runner: runner
        )
        .resolve(Self.record)

        #expect(location?.path == "/home/dev/src/api")
        #expect(location?.provenance == .multiplexer)
        #expect(await runner.directories == ["/home/dev/src/api/services"])
    }

    @Test func herdrOutsideARepositoryKeepsThePaneDirectory() async {
        let adapter = SnapshotAdapter(
            kind: .herdr,
            pane: pane(workingDirectory: "/home/dev/notes", repositoryRoot: nil)
        )
        let runner = RootRunner(output: "", exitCode: 128)

        let location = await MultiplexerPathResolver(
            adapter: adapter,
            sessionID: Self.session,
            runner: runner
        )
        .resolve(Self.record)

        #expect(location?.path == "/home/dev/notes")
    }

    @Test func tmuxNeverAsksGit() async {
        let adapter = SnapshotAdapter(
            kind: .tmux,
            pane: pane(workingDirectory: "/home/dev/src/api/services", repositoryRoot: nil)
        )
        let runner = RootRunner(output: "/home/dev/src/api\n", exitCode: 0)

        let location = await MultiplexerPathResolver(
            adapter: adapter,
            sessionID: Self.session,
            runner: runner
        )
        .resolve(Self.record)

        #expect(location?.path == "/home/dev/src/api/services")
        #expect(await runner.directories.isEmpty)
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

    func focus(_ target: MuxTarget) async throws {}
    func switchSession(to target: MuxSession.ID, from current: MuxSession.ID) async throws {}
    func attachCommand(_ target: MuxTarget) -> String { "" }
}

private actor RootRunner: RemoteCommandRunner {
    private let output: String
    private let exitCode: Int32
    private(set) var directories = [String]()

    init(output: String, exitCode: Int32) {
        self.output = output
        self.exitCode = exitCode
    }

    func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        directories += batch.commands.compactMap { command in
            command.arguments.firstIndex(of: "-C").map { command.arguments[$0 + 1] }
        }
        return BatchResponse(
            sections: batch.commands.map { command in
                CommandSection(
                    label: command.label,
                    bytes: Data(output.utf8),
                    exitCode: exitCode,
                    truncated: false
                )
            }
        )
    }
}
