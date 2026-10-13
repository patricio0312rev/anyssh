import AnySSHCore
import AnySSHMocks
import Foundation
import Sessions
import Testing

@testable import AnySSHUI

@Suite @MainActor struct ReconnectLeftBehindSessionTests {
    @Test func foregroundDialsOnlyTheSessionInFrontOfTheUser() async throws {
        let fixture = await LeftBehindFixture.make()
        let model = fixture.model
        let alphaID = try #require(fixture.session(on: LeftBehindFixture.alpha.id))
        let bravoID = try #require(fixture.session(on: LeftBehindFixture.bravo.id))
        model.markBackgroundedSessions()
        model.startReconnectMonitoring()
        let dialsBefore = fixture.dials.count

        model.handleForeground()
        try await waitUntil { model.registry[bravoID]?.state == .connected }

        #expect(fixture.dials.count == dialsBefore + 1)
        #expect(fixture.dials.remoteIDs.last == LeftBehindFixture.bravo.id)
        #expect(model.reconnectCoordinator.lastTriggeredSessionIDs == [bravoID])
        #expect(model.registry[alphaID]?.state == .disconnected(.backgrounded))
        #expect(model.registry[alphaID]?.reconnectAttempts == 0)
    }

    @Test func foregroundDialsNothingWhileTheWorkspaceIsDismissed() async throws {
        let fixture = await LeftBehindFixture.make(isPresented: { false })
        let model = fixture.model
        let bravoID = try #require(fixture.session(on: LeftBehindFixture.bravo.id))
        model.markBackgroundedSessions()
        model.startReconnectMonitoring()
        let dialsBefore = fixture.dials.count

        model.handleForeground()
        await model.reconnectCoordinator.requestReconnects(for: .foreground)

        #expect(fixture.dials.count == dialsBefore)
        #expect(model.reconnectCoordinator.lastTriggeredSessionIDs.isEmpty)
        #expect(model.registry[bravoID]?.state == .disconnected(.backgrounded))
    }

    @Test func activatingABackgroundedSessionForcesASingleDial() async throws {
        let fixture = await LeftBehindFixture.make()
        let model = fixture.model
        let alphaID = try #require(fixture.session(on: LeftBehindFixture.alpha.id))
        let bravoID = try #require(fixture.session(on: LeftBehindFixture.bravo.id))
        model.markBackgroundedSessions()
        let dialsBefore = fixture.dials.count

        model.select(alphaID)
        try await waitUntil { model.registry[alphaID]?.state == .connected }

        #expect(fixture.dials.count == dialsBefore + 1)
        #expect(fixture.dials.remoteIDs.last == LeftBehindFixture.alpha.id)
        #expect(model.registry[bravoID]?.state == .disconnected(.backgrounded))
    }

    @Test func aLeftBehindPassphraseSessionNeverAsksForBiometricsOnForeground() async throws {
        let biometrics = CountingBiometrics()
        let credential = GatedCredential(
            authenticator: biometrics,
            secrets: InMemorySecretStore(),
            reference: SecretReference(
                remoteID: LeftBehindFixture.alpha.id,
                kind: .keyPassphrase
            )
        )
        let fixture = await LeftBehindFixture.make(credential: credential)
        let model = fixture.model
        let bravoID = try #require(fixture.session(on: LeftBehindFixture.bravo.id))
        #expect(await biometrics.authentications == 1)
        model.markBackgroundedSessions()
        model.startReconnectMonitoring()

        model.handleForeground()
        try await waitUntil { model.registry[bravoID]?.state == .connected }

        #expect(await biometrics.authentications == 1)
    }

    @Test func aPathChangeRedialsAStoredPasswordTabButNotAHiddenPassphraseOne() async throws {
        let biometrics = CountingBiometrics()
        let credential = GatedCredential(
            authenticator: biometrics,
            secrets: InMemorySecretStore(),
            reference: SecretReference(
                remoteID: LeftBehindFixture.alpha.id,
                kind: .keyPassphrase
            )
        )
        let secrets = InMemorySecretStore(secrets: [
            SecretReference(remoteID: LeftBehindFixture.bravo.id, kind: .password): Data("pw".utf8)
        ])
        let fixture = await LeftBehindFixture.make(
            credential: credential,
            secrets: secrets,
            isPresented: { false }
        )
        let model = fixture.model
        let alphaID = try #require(fixture.session(on: LeftBehindFixture.alpha.id))
        let bravoID = try #require(fixture.session(on: LeftBehindFixture.bravo.id))
        #expect(await biometrics.authentications == 1)
        model.markBackgroundedSessions()
        model.startReconnectMonitoring()
        let dialsBefore = fixture.dials.count

        model.reconnectCoordinator.handlePathChange()
        try await waitUntil { model.registry[bravoID]?.state == .connected }

        #expect(fixture.dials.count == dialsBefore + 1)
        #expect(fixture.dials.remoteIDs.last == LeftBehindFixture.bravo.id)
        #expect(model.reconnectCoordinator.lastTriggeredSessionIDs == [bravoID])
        #expect(model.registry[alphaID]?.state == .disconnected(.backgrounded))
        #expect(await biometrics.authentications == 1)
    }
}

@MainActor
private struct LeftBehindFixture {
    static let alpha = Remote(
        id: RemoteID(rawValue: "alpha"),
        name: "alpha",
        host: "10.0.0.1",
        username: "dev",
        authMethod: .publicKey
    )
    static let bravo = Remote(
        id: RemoteID(rawValue: "bravo"),
        name: "bravo",
        host: "10.0.0.2",
        username: "dev",
        authMethod: .password
    )

    let model: SessionWorkspaceModel
    let dials: DialLog

    static func make(
        credential: GatedCredential? = nil,
        secrets: (any SecretStore)? = nil,
        isPresented: @escaping @MainActor () -> Bool = { true }
    ) async -> LeftBehindFixture {
        let dials = DialLog()
        let model = SessionWorkspaceModel(
            registry: SessionRegistry(),
            remotes: [alpha, bravo],
            activeSessionID: nil,
            connections: [:],
            makeEngine: { size in SwiftTermEngine(size: size, renderer: .coreText) },
            makeConnection: { remote, _ in
                dials.record(remote.id)
                return BiometricGatedConnection(
                    connectionID: ConnectionID(
                        rawValue: "\(remote.id.rawValue).\(dials.count)"
                    ),
                    credential: remote.id == alpha.id ? credential : nil
                )
            },
            secrets: secrets,
            reconnectCoordinator: ReconnectCoordinator(pathSignal: ScriptedPathSignal()),
            isWorkspacePresented: isPresented
        )
        await model.open(remote: alpha)
        await model.open(remote: bravo)
        return LeftBehindFixture(model: model, dials: dials)
    }

    func session(on remoteID: RemoteID) -> SessionID? {
        model.registry.sessions.first { $0.remoteID == remoteID }?.id
    }
}

@MainActor
private final class DialLog {
    private(set) var remoteIDs: [RemoteID] = []

    var count: Int { remoteIDs.count }

    func record(_ id: RemoteID) {
        remoteIDs.append(id)
    }
}
