import AnySSHCore
import Foundation

public struct TmuxAdapter: MultiplexerAdapter {
    public nonisolated let kind: MultiplexerKind = .tmux
    public nonisolated let capabilities: MultiplexerCapabilities = .tmux

    private let runner: any RemoteCommandRunner
    private let binaryPath: String
    private let parser = TmuxParser()

    public init(runner: any RemoteCommandRunner, binaryPath: String = "tmux") {
        self.runner = runner
        self.binaryPath = binaryPath
    }

    public func detect() async throws -> MultiplexerInfo {
        let batch = TmuxCommands.detect(binary: binaryPath)
        let response = try await runner.run(batch)
        let section = try MuxCommandSupport.section(
            label: TmuxCommands.detectLabel,
            in: response,
            batch: batch
        )
        let version = try parser.version(from: MuxCommandSupport.text(section))
        return MultiplexerInfo(
            kind: .tmux,
            binaryPath: binaryPath,
            version: version,
            protocolVersion: nil
        )
    }

    public func listSessions() async throws -> [MuxSession] {
        let batch = TmuxCommands.sessions(binary: binaryPath)
        let response = try await runner.run(batch)
        let section = try MuxCommandSupport.section(
            label: TmuxCommands.sessionsLabel,
            in: response,
            batch: batch
        )
        return try parser.sessions(from: MuxCommandSupport.text(section))
    }

    public func snapshot(_ session: MuxSession.ID) async throws -> MuxSnapshot {
        let batch = TmuxCommands.snapshot(binary: binaryPath)
        let response = try await runner.run(batch)
        let sessionsSection = try MuxCommandSupport.section(
            label: TmuxCommands.sessionsLabel,
            in: response,
            batch: batch
        )
        let windowsSection = try MuxCommandSupport.section(
            label: TmuxCommands.windowsLabel,
            in: response,
            batch: batch
        )
        let panesSection = try MuxCommandSupport.section(
            label: TmuxCommands.panesLabel,
            in: response,
            batch: batch
        )
        return try parser.snapshot(
            sessionID: session,
            sessionsText: MuxCommandSupport.text(sessionsSection),
            windowsText: MuxCommandSupport.text(windowsSection),
            panesText: MuxCommandSupport.text(panesSection)
        )
    }

    public func readPane(_ pane: MuxPane.ID, lines: Int) async throws -> String {
        let batch = TmuxCommands.capture(
            binary: binaryPath,
            pane: pane.rawValue,
            lines: lines
        )
        let response = try await runner.run(batch)
        let section = try MuxCommandSupport.section(
            label: TmuxCommands.captureLabel,
            in: response,
            batch: batch
        )
        return MuxCommandSupport.text(section)
    }

    public func keyBindings() async throws -> MuxKeyBindings {
        let batch = TmuxCommands.prefix(binary: binaryPath)
        let response = try await runner.run(batch)
        let section = try MuxCommandSupport.section(
            label: TmuxCommands.prefixLabel,
            in: response,
            batch: batch
        )
        let prefix = parser.prefix(from: MuxCommandSupport.text(section))
        return MuxKeyBindings(prefix: prefix, chords: [:])
    }

    public func attachCommand(_ target: MuxTarget) -> String {
        MuxAttachCommand.tmux(binary: binaryPath, target: target)
    }
}
