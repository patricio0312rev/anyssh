import AnySSHCore
import Foundation
import Synchronization

public final class HerdrAdapter: MultiplexerAdapter {
    public nonisolated let kind: MultiplexerKind = .herdr
    public nonisolated let capabilities: MultiplexerCapabilities = .herdr

    private let runner: any RemoteCommandRunner
    private let parser = HerdrParser()
    private let fixedBinaryPath: String?
    private let cachedPath = Mutex<String?>(nil)

    public init(runner: any RemoteCommandRunner, binaryPath: String? = nil) {
        self.runner = runner
        self.fixedBinaryPath = binaryPath
    }

    public func detect() async throws -> MultiplexerInfo {
        let status = try await clientStatus()
        cachedPath.withLock { $0 = status.path }
        return MultiplexerInfo(
            kind: .herdr,
            binaryPath: status.path,
            version: status.version,
            protocolVersion: status.protocolVersion
        )
    }

    public func listSessions() async throws -> [MuxSession] {
        let binary = try await resolvedBinary()
        let batch = HerdrCommands.sessions(binary: binary)
        let response = try await runner.run(batch)
        let section = try MuxCommandSupport.section(
            label: HerdrCommands.sessionsLabel,
            in: response,
            batch: batch
        )
        return try parser.sessions(from: MuxCommandSupport.text(section))
    }

    public func snapshot(_ session: MuxSession.ID) async throws -> MuxSnapshot {
        let binary = try await resolvedBinary()
        let sessions = try await listSessions()
        let matched =
            sessions.first(where: { $0.id == session })
            ?? MuxSession(id: session, name: session.rawValue, isAttached: false)
        let batch = HerdrCommands.snapshot(binary: binary, session: session.rawValue)
        let response = try await runner.run(batch)
        let section = try MuxCommandSupport.section(
            label: HerdrCommands.snapshotLabel,
            in: response,
            batch: batch
        )
        return try parser.snapshot(from: MuxCommandSupport.text(section), session: matched)
    }

    public func readPane(_ pane: MuxPane.ID, lines: Int) async throws -> String {
        let binary = try await resolvedBinary()
        let batch = HerdrCommands.paneRead(
            binary: binary,
            pane: pane.rawValue,
            lines: lines,
            session: nil
        )
        let response = try await runner.run(batch)
        let section = try MuxCommandSupport.section(
            label: HerdrCommands.paneReadLabel,
            in: response,
            batch: batch
        )
        return try parser.paneText(from: MuxCommandSupport.text(section))
    }

    public func keyBindings() async throws -> MuxKeyBindings {
        let batch = HerdrCommands.config(binary: try await resolvedBinary())
        let response = try await runner.run(batch)
        let section = try MuxCommandSupport.section(
            label: HerdrCommands.configLabel,
            in: response,
            batch: batch
        )
        return parser.keyBindings(from: MuxCommandSupport.text(section))
    }

    public func focus(_ target: MuxTarget) async throws {
        let binary = try await resolvedBinary()
        let session = target.session.rawValue
        if let pane = target.pane {
            let batch = HerdrCommands.focusAgent(
                binary: binary,
                session: session,
                pane: pane.rawValue
            )
            let response = try await runner.run(batch)
            guard target.group != nil else {
                _ = try MuxCommandSupport.section(
                    label: HerdrCommands.focusAgentLabel,
                    in: response,
                    batch: batch
                )
                return
            }
            let focused = response.sections.first { $0.label == HerdrCommands.focusAgentLabel }
            if focused?.exitCode == 0 { return }
        }
        guard let group = target.group else { throw ErrorState.mux(.attachTargetVanished) }
        try await focusTab(binary: binary, session: session, group: group.rawValue)
    }

    public func attachCommand(_ target: MuxTarget) -> String {
        let binary = cachedPath.withLock { $0 } ?? fixedBinaryPath ?? "herdr"
        return MuxAttachCommand.herdr(binary: binary, target: target)
    }

    private func focusTab(binary: String, session: String, group: String) async throws {
        let batch = HerdrCommands.focusTab(binary: binary, session: session, group: group)
        let response = try await runner.run(batch)
        _ = try MuxCommandSupport.section(
            label: HerdrCommands.focusTabLabel,
            in: response,
            batch: batch
        )
    }

    private func resolvedBinary() async throws -> String {
        if let cached = cachedPath.withLock({ $0 }) { return cached }
        let status = try await clientStatus()
        cachedPath.withLock { $0 = status.path }
        return status.path
    }

    private func clientStatus() async throws -> HerdrClientStatus {
        let batch: RemoteBatch
        if let fixedBinaryPath {
            batch = HerdrCommands.detect(binary: fixedBinaryPath)
        } else {
            batch = HerdrCommands.detect()
        }
        let response = try await runner.run(batch)
        guard let section = response.sections.first(where: { $0.label == HerdrCommands.detectLabel })
        else {
            throw ErrorState.command(.responseUnreadable)
        }
        if section.exitCode == 127 { throw ErrorState.mux(.absent) }
        do {
            return try parser.clientStatus(from: MuxCommandSupport.text(section))
        } catch HerdrParseError.protocolMismatch {
            throw ErrorState.mux(.protocolMismatch)
        } catch HerdrParseError.notInstalled {
            throw ErrorState.mux(.absent)
        } catch {
            throw ErrorState.command(.responseUnreadable)
        }
    }
}
