import AnySSHCore
import AnySSHMocks
import Foundation
import Testing

@testable import AnySSHUI

@Suite @MainActor struct RemotesDeletionTests {
    private let id = RemoteID(rawValue: "workstation")

    private func seeded() -> InMemorySecretStore {
        InMemorySecretStore(
            secrets: Dictionary(
                uniqueKeysWithValues: SecretKind.allCases.map {
                    (SecretReference(remoteID: id, kind: $0), Data("secret".utf8))
                }
            )
        )
    }

    @Test func deletingAHostRemovesEverySecretStoredForIt() async throws {
        let secrets = seeded()
        let model = RemotesListModel(store: MockRemoteStore(scenario: "single"), secrets: secrets)
        await model.load()

        for kind in SecretKind.allCases {
            #expect(try await secrets.secret(SecretReference(remoteID: id, kind: kind)) != nil)
        }

        await model.delete(id)

        #expect(model.refusal == nil)
        #expect(model.remotes.isEmpty)
        for kind in SecretKind.allCases {
            #expect(try await secrets.secret(SecretReference(remoteID: id, kind: kind)) == nil)
        }
    }

    @Test func deletingLeavesAnotherHostsSecretsAlone() async throws {
        let other = SecretReference(remoteID: RemoteID(rawValue: "build-box"), kind: .password)
        let secrets = InMemorySecretStore(secrets: [other: Data("keep".utf8)])
        let model = RemotesListModel(store: MockRemoteStore(scenario: "single"), secrets: secrets)
        await model.load()

        await model.delete(id)

        #expect(try await secrets.secret(other) != nil)
    }
}
