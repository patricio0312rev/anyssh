import AnySSHCore
import Foundation
import Sessions

extension SessionWorkspaceModel {
    public func openAdditional(remote: Remote) async {
        await open(remote: remote, resumingExisting: false)
    }

    public func open(remote: Remote) async {
        await open(remote: remote, resumingExisting: true)
    }

    public func openAdditionalSession() async {
        guard let record = activeRecord, let remote = remotes[record.remoteID] else { return }
        await openAdditional(remote: remote)
    }

    private func open(remote: Remote, resumingExisting: Bool) async {
        clearOpenFailure()
        remotes[remote.id] = remote
        if resumingExisting, let resumed = await resumeExisting(on: remote.id) {
            if resumed { shouldPresentSwitcher = true }
            return
        }
        await closeDeadSessions(on: remote.id)
        guard let makeConnection else { return }
        let sessionID = SessionID(rawValue: UUID().uuidString.lowercased())
        let bridge = makeAuthBridge(for: remote)
        let connection = makeConnection(remote, bridge)
        let record = SessionOpenService.makeRecord(
            sessionID: sessionID,
            remote: remote,
            connectionID: connection.connectionID,
            at: Date.now
        )
        _ = registry.open(record)
        connections[sessionID] = connection
        if let bridge {
            authBridges[sessionID] = bridge
            activeAuthBridge = bridge
        }
        lastRemote = remote
        let surface = attach(sessionID, connection: connection)
        await activateOpened(sessionID)
        await startDisplay(
            sessionID: sessionID,
            remoteID: remote.id,
            surface: surface,
            connection: connection,
            bridge: bridge,
            remoteName: remote.name
        )
        try? await StartupCommandSender().send(on: connection, remote: remote)
        let start = StartDirectoryPolicy.path(
            remembered: lastDirectories.path(for: remote.id),
            configured: remote.startPath
        )
        try? await WorkingDirectoryRestorer().send(
            on: connection,
            workspace: start.map { WorkspaceLocation(path: $0, provenance: .process) }
        )
    }

    private func resumeExisting(on remoteID: RemoteID) async -> Bool? {
        let live = SessionOpenService.liveSessionIDs(on: remoteID, in: registry)
        guard let first = live.first else { return nil }
        await resume(first)
        return live.count > 1
    }

    private func activateOpened(_ sessionID: SessionID) async {
        if let outgoing = activeSessionID, outgoing != sessionID,
            store.surface(for: outgoing) != nil, scopes[outgoing] != nil
        {
            beginSwitch(to: sessionID)
            await completeSwitch()
        } else {
            activate(sessionID)
        }
    }

    public func close(_ id: SessionID) async {
        await tearDown(id, reason: .closedByUser)
        guard activeSessionID == id else { return }
        promoteNextSession()
    }

    private func resume(_ id: SessionID) async {
        if id == activeSessionID {
            store.surface(for: id)?.startDraining()
            registry.touch(id, at: Date.now)
            return
        }
        let canSwitch =
            activeSessionID != nil
            && store.surface(for: id) != nil
            && activeSessionID.flatMap { store.surface(for: $0) } != nil
            && activeSessionID.flatMap { scopes[$0] } != nil
        if canSwitch {
            beginSwitch(to: id)
            await completeSwitch()
            return
        }
        activate(id)
        registry.touch(id, at: Date.now)
        store.surface(for: id)?.startDraining()
    }

    private func closeDeadSessions(on remoteID: RemoteID) async {
        for id in SessionOpenService.deadSessionIDs(on: remoteID, in: registry) {
            await close(id)
        }
    }

    func restoreDirectory(for sessionID: SessionID, connection: any RemoteConnection) async {
        guard let workspace = registry[sessionID]?.workspace else { return }
        try? await WorkingDirectoryRestorer().send(on: connection, workspace: workspace)
    }
}
