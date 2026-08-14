import AnySSHCore
import AnySSHMocks
import AnySSHUI
import Foundation
import Observation
import Sessions
import SwiftUI

@MainActor
@Observable
final class SessionController {
    let secrets: any SecretStore
    let hostKeys: any HostKeyStore
    let isMock: Bool
    let restoreStore: SessionRestoreStore
    let restoreEnabled: Bool
    let activityCoordinator: SessionActivityCoordinator
    let jobAlertScheduler: any NotificationScheduler = RecordingNotificationScheduler()

    private(set) var workspace: SessionWorkspaceModel?
    var isPresentingWorkspace = false
    let restoreCoordinator: SessionRestoreCoordinator

    private var pendingNotification: (SessionID, MuxPaneID?)?

    init(
        secrets: any SecretStore,
        hostKeys: any HostKeyStore,
        isMock: Bool,
        restoreStore: SessionRestoreStore,
        restoreEnabled: Bool,
        activityPresenter: any ActivityPresenter
    ) {
        self.secrets = secrets
        self.hostKeys = hostKeys
        self.isMock = isMock
        self.restoreStore = restoreStore
        self.restoreEnabled = restoreEnabled
        activityCoordinator = SessionActivityCoordinator(
            presenter: activityPresenter,
            clock: SystemClock()
        )
        restoreCoordinator = SessionRestoreCoordinator(store: restoreStore)
    }

    func selectSession(_ id: SessionID, pane: MuxPaneID? = nil) {
        guard let workspace else {
            pendingNotification = (id, pane)
            return
        }
        workspace.select(id, pane: pane)
    }

    func open(_ remote: Remote) async {
        let model = workspace ?? makeWorkspace()
        workspace = model
        deliverPendingNotification(to: model)
        isPresentingWorkspace = true
        await model.open(remote: remote)
    }

    func leaveWorkspace() {
        isPresentingWorkspace = false
        if let workspace {
            Task { await workspace.endActivities() }
        }
        Task { restoreCoordinator.noteLeftWorkspace() }
    }

    func activityPhaseChanged(_ phase: ScenePhase) async {
        await activityCoordinator.setForeground(phase == .active)
    }

    func restoredWorkspace(remotes: [Remote]) -> SessionWorkspaceModel? {
        guard restoreEnabled else { return nil }
        guard let snapshot = try? restoreStore.load(),
            !snapshot.records.isEmpty,
            snapshot.activeSessionID != nil
        else {
            return nil
        }
        try? restoreStore.save(
            SessionRestoreSnapshot(
                records: snapshot.records,
                transcripts: snapshot.transcripts,
                activeSessionID: nil
            )
        )
        let model = makeRestoredWorkspace(from: snapshot, remotes: remotes)
        workspace = model
        restoreCoordinator.start(source: model)
        deliverPendingNotification(to: model)
        return model
    }

    private func deliverPendingNotification(to model: SessionWorkspaceModel) {
        guard let pending = pendingNotification else { return }
        pendingNotification = nil
        model.select(pending.0, pane: pending.1)
    }
}
