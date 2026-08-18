import AnySSHCore
import Foundation
import Multiplexers
import Sessions
import TerminalEmulator

extension SessionWorkspaceModel {
    @discardableResult
    func attach(
        _ sessionID: SessionID,
        connection: any RemoteConnection
    ) -> TerminalSurface {
        scopes[sessionID] = SessionActivityScope(sessionID: sessionID, connection: connection)
        let surface = attachSurface(sessionID, connection: connection)
        let bar = AccessoryBarModel(
            remoteStoreLocation: AccessoryLayout.defaultLocation,
            writer: connection,
            bindings: muxBindings
        )
        barModels[sessionID] = bar
        surface.engine.transformInput = { [weak bar] bytes in
            bar?.applyLatch(to: bytes) ?? Array(bytes)
        }
        return surface
    }

    func attachSurface(
        _ sessionID: SessionID,
        connection: any RemoteConnection
    ) -> TerminalSurface {
        store.open(
            sessionID,
            on: connection,
            deliverMetadata: { [weak self] metadata in
                self?.deliverMetadata(metadata, for: sessionID)
            }
        )
    }

    private func deliverMetadata(_ metadata: TerminalMetadata, for sessionID: SessionID) {
        if let title = metadata.title {
            rememberAgentSessionTitle(title, for: sessionID, replacing: true)
            Task { await detectAgent(for: sessionID) }
        }
        updateActivity(for: sessionID)
        guard metadata.didRing, activeSessionID != sessionID, let scheduler = jobAlerts else {
            return
        }
        let title = agentKind(for: sessionID)?.name ?? Self.unknownAgentName
        Task {
            await scheduler.schedule(
                JobAlertRequest(
                    alert: JobFinishAlert(title: title, body: Self.attentionBody),
                    sessionID: sessionID
                )
            )
        }
    }

    func probeSession(
        _ sessionID: SessionID
    ) async -> (processNames: [String], directory: String?) {
        guard let connection = connections[sessionID],
            let port = await connection.clientPort
        else {
            return ([], nil)
        }
        let batch = RemoteBatch(commands: [
            RemoteCommand(
                label: "foreground",
                arguments: ["sh", "-c", ForegroundProcessCommand.script(clientPort: port)],
                byteCap: Self.probeByteCap
            )
        ])
        guard let response = try? await connection.run(batch),
            let result = response.sections.first,
            let text = String(data: result.bytes, encoding: .utf8)
        else {
            return ([], nil)
        }
        return (
            ForegroundProcessCommand.processNames(from: text),
            ForegroundProcessCommand.workingDirectory(from: text)
        )
    }

    static let unknownAgentName = "Agent"
    static let attentionBody = "The session is waiting for your attention."
    static let probeByteCap = 4096
}
