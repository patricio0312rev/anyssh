import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite struct CredentialResolverKeyMaterialTests {
    private static var keyDirectory: URL {
        FileManager.default.temporaryDirectory
            .appending(path: "anyssh-keys", directoryHint: .isDirectory)
    }

    @Test func doesNotWriteTheKeyToDisk() async throws {
        try? FileManager.default.removeItem(at: Self.keyDirectory)

        let credential = try await resolveKey(remoteID: "resolver.disk")

        guard case .privateKey(let key) = credential else {
            Issue.record("expected a private-key credential")
            return
        }
        #expect(key.privateKey == Self.keyBytes)
        #expect(!FileManager.default.fileExists(atPath: Self.keyDirectory.path))
    }

    @Test func doesNotAccumulateAcrossDials() async throws {
        try? FileManager.default.removeItem(at: Self.keyDirectory)

        for index in 0..<3 {
            _ = try await resolveKey(remoteID: "resolver.dial\(index)")
        }

        let contents =
            (try? FileManager.default.contentsOfDirectory(atPath: Self.keyDirectory.path)) ?? []
        #expect(contents.isEmpty)
    }

    private static let keyBytes = Data("not-a-real-key".utf8)

    private func resolveKey(remoteID rawID: String) async throws -> AuthCredential {
        let id = RemoteID(rawValue: rawID)
        let secrets = StubSecretStore(secrets: [
            SecretReference(remoteID: id, kind: .privateKey): Self.keyBytes
        ])
        let remote = Remote(
            id: id,
            name: "host",
            host: "example.test",
            username: "root",
            authMethod: .publicKey
        )
        return try await CredentialResolver.resolve(remote: remote, secrets: secrets)
    }
}

private actor StubSecretStore: SecretStore {
    private let secrets: [SecretReference: Data]

    init(secrets: [SecretReference: Data]) {
        self.secrets = secrets
    }

    func secret(_ reference: SecretReference) async throws -> Data? {
        secrets[reference]
    }

    func store(_ secret: Data, at reference: SecretReference) async throws {}

    func remove(_ reference: SecretReference) async throws {}
}
