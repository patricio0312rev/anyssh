import AnySSHCore
import Foundation

public struct FixtureMultiplexerAdapter: MultiplexerAdapter {
    public nonisolated let kind: MultiplexerKind
    public nonisolated let capabilities: MultiplexerCapabilities

    private let info: MultiplexerInfo
    private let sessions: [MuxSession]
    private let snapshots: [MuxSessionID: MuxSnapshot]
    private let bindings: MuxKeyBindings
    private let paneText: String
    private let detectError: ErrorState?

    public let focusLog = MuxFocusLog()
    public let switchLog = MuxSwitchLog()

    public init(fixture: MuxFixture) {
        kind = fixture.kind
        capabilities = fixture.capabilities
        switch fixture {
        case .tmuxMain, .tmuxCluster, .herdrDefault, .herdrCluster:
            let built = Self.tree(for: fixture)
            info = built.info
            sessions = built.sessions
            snapshots = built.snapshots
            bindings = built.bindings
            paneText = built.paneText
            detectError = nil
        case .herdrProtocolMismatch:
            info = MultiplexerInfo(
                kind: .herdr,
                binaryPath: "/home/dev/.local/bin/herdr",
                version: "0.7.0",
                protocolVersion: 18
            )
            sessions = []
            snapshots = [:]
            bindings = MuxKeyBindings(prefix: "ctrl+b", chords: [:])
            paneText = ""
            detectError = .mux(.protocolMismatch)
        case .absent:
            info = MultiplexerInfo(kind: .none, binaryPath: "", version: "", protocolVersion: nil)
            sessions = []
            snapshots = [:]
            bindings = MuxKeyBindings(prefix: "", chords: [:])
            paneText = ""
            detectError = .mux(.absent)
        }
    }

    public init?(deepLink: URL) {
        guard deepLink.scheme == "anyssh", deepLink.host == "mux",
            let fixture = MuxFixture(rawValue: deepLink.pathComponents.last ?? "")
        else { return nil }
        self.init(fixture: fixture)
    }

    public func detect() async throws -> MultiplexerInfo {
        if let detectError { throw detectError }
        return info
    }

    public func listSessions() async throws -> [MuxSession] {
        if let detectError { throw detectError }
        return sessions
    }

    public func snapshot(_ session: MuxSession.ID) async throws -> MuxSnapshot {
        if let detectError { throw detectError }
        guard let snapshot = snapshots[session] else {
            throw ErrorState.mux(.attachTargetVanished)
        }
        return snapshot.focusing(await focusLog.focusedGroup(in: session))
    }

    public func readPane(_ pane: MuxPane.ID, lines: Int) async throws -> String {
        _ = pane
        _ = lines
        if let detectError { throw detectError }
        return paneText
    }

    public func keyBindings() async throws -> MuxKeyBindings {
        if let detectError { throw detectError }
        return bindings
    }

    public func focus(_ target: MuxTarget) async throws {
        if let detectError { throw detectError }
        await focusLog.record(target)
    }

    public func switchSession(to target: MuxSession.ID, from current: MuxSession.ID) async throws {
        if let detectError { throw detectError }
        guard kind == .tmux else { throw ErrorState.mux(.sessionSwitchUnsupported) }
        await switchLog.record(target: target, source: current)
    }

    public func attachCommand(_ target: MuxTarget) -> String {
        switch kind {
        case .tmux: MuxAttachCommand.tmux(binary: "tmux", target: target)
        case .herdr: MuxAttachCommand.herdr(binary: "herdr", target: target)
        case .none: ""
        }
    }
}
