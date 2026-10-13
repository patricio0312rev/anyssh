import AnySSHCore
import AnySSHMocks
import Foundation
import Sessions
import Testing

@testable import AnySSHUI

@Suite @MainActor struct SessionResumeDialTests {
    @Test func resumingASessionThatDropsDuringTheSwitchDialsOnce() async throws {
        let biometrics = RefusingBiometrics()
        let fixture = await ResumeDialFixture.make(biometrics: biometrics)
        let model = fixture.model
        let alphaID = try #require(fixture.session(on: ResumeDialFixture.alpha.id))
        let bravoID = try #require(fixture.session(on: ResumeDialFixture.bravo.id))
        #expect(model.activeSessionID == bravoID)
        let bravoScope = try #require(model.scope(for: bravoID))
        let gate = WorkGate()
        let held = Task { try await bravoScope.run { await gate.wait() } }
        try await waitUntil { await gate.isWaiting }

        let resuming = Task { await model.open(remote: ResumeDialFixture.alpha) }
        try await waitUntil { await bravoScope.cancellations == 1 }
        model.markBackgroundedSessions()
        await gate.release()
        await resuming.value
        _ = await held.result

        #expect(model.activeSessionID == alphaID)
        #expect(fixture.dials.count(for: ResumeDialFixture.alpha.id) == 2)
        #expect(await biometrics.authentications == 1)
    }
}

@MainActor
private struct ResumeDialFixture {
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
    let dials: ResumeDialLog

    static func make(biometrics: RefusingBiometrics) async -> ResumeDialFixture {
        let dials = ResumeDialLog()
        let credential = GatedCredential(
            authenticator: biometrics,
            secrets: InMemorySecretStore(),
            reference: SecretReference(remoteID: alpha.id, kind: .keyPassphrase)
        )
        let model = SessionWorkspaceModel(
            registry: SessionRegistry(),
            remotes: [alpha, bravo],
            activeSessionID: nil,
            connections: [:],
            makeEngine: { size in SwiftTermEngine(size: size, renderer: .coreText) },
            makeConnection: { remote, _ in
                dials.record(remote.id)
                let count = dials.count(for: remote.id)
                let connectionID = ConnectionID(rawValue: "\(remote.id.rawValue).\(count)")
                guard remote.id == alpha.id, count > 1 else {
                    return MockRemoteConnection(connectionID: connectionID)
                }
                return BiometricGatedConnection(connectionID: connectionID, credential: credential)
            },
            reconnectCoordinator: ReconnectCoordinator(pathSignal: ScriptedPathSignal()),
            isWorkspacePresented: { true }
        )
        await model.open(remote: alpha)
        await model.open(remote: bravo)
        return ResumeDialFixture(model: model, dials: dials)
    }

    func session(on remoteID: RemoteID) -> SessionID? {
        model.registry.sessions.first { $0.remoteID == remoteID }?.id
    }
}

@MainActor
private final class ResumeDialLog {
    private var remoteIDs: [RemoteID] = []

    func record(_ id: RemoteID) {
        remoteIDs.append(id)
    }

    func count(for id: RemoteID) -> Int {
        remoteIDs.filter { $0 == id }.count
    }
}

private actor RefusingBiometrics: BiometricAuthenticator {
    private(set) var authentications = 0

    func authenticate(reason: String) async -> BiometricResult {
        _ = reason
        authentications += 1
        return BiometricResult(.cancelled)
    }
}

private actor WorkGate {
    private(set) var isWaiting = false
    private var isReleased = false
    private var continuation: CheckedContinuation<Void, Never>?

    func wait() async {
        isWaiting = true
        guard !isReleased else { return }
        await withCheckedContinuation { continuation = $0 }
    }

    func release() {
        isReleased = true
        continuation?.resume()
        continuation = nil
    }
}
