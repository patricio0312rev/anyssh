import AnySSHCore
import Foundation
import Sessions
import Testing

@testable import AnySSHUI

@Suite @MainActor struct ReconnectAttentionScopeTests {
    @Test func aDismissedWorkspaceDialsNothing() async {
        let coordinator = ReconnectCoordinator(pathSignal: ScriptedPathSignal())
        let dialed = DialedSessions()
        coordinator.start(
            candidates: { Self.backgroundedRecords },
            attention: { .dismissed },
            onReconnect: { dialed.append($0) }
        )

        await coordinator.requestReconnects()

        #expect(coordinator.lastTriggeredSessionIDs.isEmpty)
        #expect(dialed.ids.isEmpty)
    }

    @Test func aPresentedWorkspaceDialsEngagedSessionsWithTheActiveOneFirst() async {
        let coordinator = ReconnectCoordinator(pathSignal: ScriptedPathSignal())
        let dialed = DialedSessions()
        coordinator.start(
            candidates: { Self.backgroundedRecords },
            attention: {
                ReconnectAttention(
                    isWorkspacePresented: true,
                    activeSessionID: Self.third,
                    engagedSessionIDs: [Self.first, Self.third]
                )
            },
            onReconnect: { dialed.append($0) }
        )

        await coordinator.requestReconnects()

        #expect(coordinator.lastTriggeredSessionIDs == [Self.third, Self.first])
        #expect(dialed.ids == [Self.third, Self.first])
    }

    @Test func aSessionWithoutASurfaceStaysUndialedWhileItIsNotActive() async {
        let coordinator = ReconnectCoordinator(pathSignal: ScriptedPathSignal())
        let dialed = DialedSessions()
        coordinator.start(
            candidates: { Self.backgroundedRecords },
            attention: {
                ReconnectAttention(
                    isWorkspacePresented: true,
                    activeSessionID: Self.first,
                    engagedSessionIDs: []
                )
            },
            onReconnect: { dialed.append($0) }
        )

        await coordinator.requestReconnects()

        #expect(coordinator.lastTriggeredSessionIDs == [Self.first])
        #expect(dialed.ids == [Self.first])
    }

    private static let first = SessionID(rawValue: "s1")
    private static let second = SessionID(rawValue: "s2")
    private static let third = SessionID(rawValue: "s3")

    private static var backgroundedRecords: [SessionRecord] {
        [first, second, third].map(record)
    }

    private static func record(_ id: SessionID) -> SessionRecord {
        SessionRecord(
            id: id,
            remoteID: RemoteID(rawValue: "r.\(id.rawValue)"),
            connectionID: ConnectionID(rawValue: "c.\(id.rawValue)"),
            title: id.rawValue,
            state: .disconnected(.backgrounded),
            capabilities: .ssh,
            reconnectAttempts: 0,
            createdAt: Date(timeIntervalSince1970: 0),
            lastActiveAt: Date(timeIntervalSince1970: 0)
        )
    }
}

@MainActor
private final class DialedSessions {
    private(set) var ids: [SessionID] = []

    func append(_ id: SessionID) {
        ids.append(id)
    }
}
