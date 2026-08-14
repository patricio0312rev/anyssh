import AnySSHCore
import AnySSHMocks
import AnySSHUI
import Foundation
import SSHTransport
import Sessions
import SwiftUI

extension SessionController {
    func makeRestoredWorkspace(
        from snapshot: SessionRestoreSnapshot,
        remotes: [Remote]
    ) -> SessionWorkspaceModel {
        let remoteByID = Dictionary(uniqueKeysWithValues: remotes.map { ($0.id, $0) })
        let restorable = snapshot.records.compactMap { record in
            remoteByID[record.remoteID].map { (record: record, remote: $0) }
        }
        let records = restorable.map(\.record)
        let connections: [SessionID: any RemoteConnection] = restorable.reduce(into: [:]) {
            connections, pair in
            connections[pair.record.id] =
                isMock
                ? MockEchoConnection(connectionID: pair.record.connectionID)
                : ConnectionFactory.make(
                    remote: pair.remote,
                    secrets: secrets,
                    hostKeys: hostKeys,
                    connectionID: pair.record.connectionID
                )
        }
        let model = makeWorkspace(
            registry: SessionRegistry(records),
            remotes: remotes,
            activeSessionID: validActiveID(in: records, snapshot: snapshot),
            connections: connections
        )
        for (id, lines) in snapshot.transcripts {
            guard let surface = model.surface(for: id) else { continue }
            SessionRestoreTranscript.restore(lines, into: surface.engine)
        }
        return model
    }

    private func validActiveID(
        in records: [SessionRecord],
        snapshot: SessionRestoreSnapshot
    ) -> SessionID? {
        if let active = snapshot.activeSessionID, records.contains(where: { $0.id == active }) {
            return active
        }
        return records.first?.id
    }

    func makeWorkspace(
        registry: SessionRegistry,
        remotes: [Remote],
        activeSessionID: SessionID?,
        connections: [SessionID: any RemoteConnection]
    ) -> SessionWorkspaceModel {
        let secrets = secrets
        let hostKeys = hostKeys
        let isMock = isMock
        return SessionWorkspaceModel(
            registry: registry,
            remotes: remotes,
            activeSessionID: activeSessionID,
            connections: connections,
            makeEngine: { size in SwiftTermEngine(size: size, renderer: .metal) },
            makeConnection: { remote, bridge in
                if isMock {
                    return MockEchoConnection(
                        connectionID: ConnectionID(
                            rawValue: "\(remote.id.rawValue).\(UUID().uuidString.prefix(8))"
                        )
                    )
                }
                return ConnectionFactory.make(
                    remote: remote,
                    secrets: secrets,
                    hostKeys: hostKeys,
                    answering: bridge?.answering
                )
            },
            secrets: secrets,
            hostKeys: hostKeys,
            layoutDirectory: layoutDirectory,
            activityCoordinator: activityCoordinator,
            jobAlertScheduler: jobAlertScheduler,
            makeBrowserServices: browserServiceFactory
        )
    }

    func makeWorkspace() -> SessionWorkspaceModel {
        makeWorkspace(
            registry: SessionRegistry(),
            remotes: [],
            activeSessionID: nil,
            connections: [:]
        )
    }

    private var browserServiceFactory: SessionWorkspaceModel.BrowserServiceFactory {
        guard isMock else { return SessionWorkspaceModel.remoteBrowserServices }
        return { _, _ in SessionWorkspaceAssembly.mockBrowserServices }
    }

    private var layoutDirectory: URL? {
        guard !isMock else { return nil }
        return URL.applicationSupportDirectory.appending(path: "AnySSH")
    }
}
