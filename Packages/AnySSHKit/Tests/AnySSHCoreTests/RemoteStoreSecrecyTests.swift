import Foundation
import Testing

@testable import AnySSHCore

extension RemoteStoreTests {
    static let forbidden = ["password", "passphrase", "BEGIN OPENSSH", secret]
    static let secret = "correct-horse-battery-staple-🔑"

    static let expectedKeys: Set<String> = [
        "id", "name", "host", "port", "username", "auth", "startPath", "startupCommand", "tag",
        "orderIndex", "deviceType", "deviceTypeSource",
    ]

    @Test func theStoreFileCarriesNoCredentialLiteral() async throws {
        let directory = TemporaryDirectory()
        defer { directory.remove() }

        let store = FileRemoteStore(directory: directory.url)
        for method in AuthMethod.allCases {
            try await store.save(RemoteStoreFixture.authenticated(by: method))
        }
        try await store.save(RemoteStoreFixture.awkward)

        let written = try directory.contents()
        for literal in Self.forbidden {
            #expect(
                written.range(of: literal, options: .caseInsensitive) == nil,
                "store file contains \(literal)"
            )
        }
    }

    @Test func theWrittenKeysAreExactlyTheDeclaredOnes() async throws {
        let directory = TemporaryDirectory()
        defer { directory.remove() }

        try await FileRemoteStore(directory: directory.url).save(RemoteStoreFixture.awkward)

        let encoded = try Data(contentsOf: directory.storeFile)
        let root = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        let envelope = try #require(root)
        #expect(Set(envelope.keys) == ["schemaVersion", "remotes"])

        let records = try #require(envelope["remotes"] as? [[String: Any]])
        #expect(records.map { Set($0.keys) } == [Self.expectedKeys])
    }

    @Test func aFutureSchemaVersionIsRefused() async throws {
        let directory = TemporaryDirectory()
        defer { directory.remove() }
        try directory.write(Self.futureFile)

        await #expect(throws: RemoteStoreError.unsupportedSchemaVersion(99)) {
            try await FileRemoteStore(directory: directory.url).remotes()
        }
        #expect(RemoteStoreError.unsupportedSchemaVersion(99).stateID == "secrets.migrationFailed")
    }

    @Test func aRefusedFileIsLeftUntouched() async throws {
        let directory = TemporaryDirectory()
        defer { directory.remove() }
        try directory.write(Self.futureFile)

        _ = try? await FileRemoteStore(directory: directory.url).remotes()

        #expect(try directory.contents() == Self.futureFile)
    }

    @Test func aFileWithoutASchemaVersionIsRefused() async throws {
        let directory = TemporaryDirectory()
        defer { directory.remove() }
        try directory.write(#"{"remotes": []}"#)

        await #expect(throws: RemoteStoreError.unreadable("no schema version")) {
            try await FileRemoteStore(directory: directory.url).remotes()
        }
    }

    static let futureFile = """
        {
          "schemaVersion" : 99,
          "remotes" : [
            {
              "id" : "from-the-future",
              "name" : "Future",
              "host" : "future.example.net",
              "port" : 22,
              "username" : "ci",
              "auth" : "key",
              "orderIndex" : 0,
              "quantumTunnel" : true
            }
          ]
        }
        """
}
