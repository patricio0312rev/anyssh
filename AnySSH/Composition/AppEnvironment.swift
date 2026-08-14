import AnySSHCore
import AnySSHMocks
import Foundation
import SSHTransport

struct AppEnvironment {
    let remoteStore: any RemoteStore
    let secretStore: any SecretStore
    let hostKeyStore: any HostKeyStore
    let reachabilityProbe: any ReachabilityProbe
    let scenario: LaunchScenario
    let migrationFailure: SecretsErrorState?
    let keychainMigrationRuns: Int
    let isMock: Bool

    init(mode: LaunchMode) {
        switch mode {
        case .live:
            scenario = .fallback
            isMock = false
            remoteStore = FileRemoteStore.applicationSupport()
            secretStore = KeychainSecretStore()
            hostKeyStore = FileHostKeyStore.applicationSupport()
            reachabilityProbe = NWConnectionProbe()
        case .mock(let name):
            let scenario = LaunchScenario(name)
            self.scenario = scenario
            isMock = true
            remoteStore = MockRemoteStore(scenario: scenario.remotesFixture)
            secretStore = InMemorySecretStore(failure: scenario.secretFailure)
            hostKeyStore = HostKeyFixtures.store(scenario.hostKeyScenario)
            reachabilityProbe = Self.mockProbe(fixture: scenario.remotesFixture)
        }
        let migration = Self.migrate()
        migrationFailure = migration.failure
        keychainMigrationRuns = migration.runs
    }

    private static func migrate() -> (failure: SecretsErrorState?, runs: Int) {
        var runs = 0
        runs += 1
        do {
            try KeychainMigrator(backend: SecItemKeychain()).run()
            return (nil, runs)
        } catch let error as SecretStoreError {
            return (error.state, runs)
        } catch {
            return (.migrationFailed, runs)
        }
    }

    private static let mockScripts: [ScriptedReachability.Script] = [
        .reachable,
        .unreachable,
        .unknown,
    ]

    private static func mockProbe(fixture: String) -> ScriptedReachability {
        let remotes = RemoteFixtures.scenario(fixture)
        let scripts = remotes.enumerated().reduce(
            into: [RemoteID: ScriptedReachability.Script]()
        ) { scripts, pair in
            scripts[pair.element.id] = mockScripts[pair.offset % mockScripts.count]
        }
        return ScriptedReachability(byRemote: scripts, default: .reachable)
    }
}
