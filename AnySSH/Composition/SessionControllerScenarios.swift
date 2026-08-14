import AnySSHCore
import AnySSHMocks
import AnySSHUI
import Foundation
import Sessions
import SwiftUI

extension SessionController {
    @ViewBuilder
    func scenarioWorkspace(_ scenario: WorkspaceScenario) -> some View {
        if scenario == .restore {
            restoreSeed()
        } else {
            SessionWorkspaceAssembly.make(scenario)
        }
    }

    private func restoreSeed() -> some View {
        let remotes = RemoteFixtures.scenario("mixed")
        let records = SessionRestoreScenario.seedIDs.enumerated().map { index, id in
            SessionRecord(
                id: SessionID(rawValue: id),
                remoteID: remotes[index].id,
                connectionID: ConnectionID(rawValue: "\(id).seed"),
                title: "restore session \(index + 1)",
                state: .connected,
                capabilities: .ssh,
                createdAt: SessionScenario.epoch,
                lastActiveAt: SessionScenario.epoch
            )
        }
        let model = makeWorkspace(
            registry: SessionRegistry(records),
            remotes: remotes,
            activeSessionID: records.first?.id,
            connections: records.reduce(into: [:]) { connections, record in
                connections[record.id] = MockEchoConnection(connectionID: record.connectionID)
            }
        )
        for (index, id) in SessionRestoreScenario.seedIDs.enumerated() {
            model.surface(for: SessionID(rawValue: id))?.engine.feed(
                ArraySlice("restore marker \(index + 1)\r\n".utf8)
            )
        }
        restoreCoordinator.start(source: model)
        return SessionWorkspaceView(model: model)
            .sessionRestoreLifecycle(model: model, coordinator: restoreCoordinator)
    }
}
