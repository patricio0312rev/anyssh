import Foundation
import Testing

@testable import AnySSHCore

@Suite struct KeyMaterialSecrecyTests {
    private static let fragments: [String] =
        KeyFixtures.all.map { String($0.text.split(separator: "\n")[1].prefix(48)) }
        + [KeyFixtures.passphrase]

    private func expectClean(_ rendered: String, _ label: Comment) {
        for fragment in Self.fragments {
            #expect(!rendered.contains(fragment), label)
        }
    }

    private func renderings(of value: some Any) -> String {
        "\(String(describing: value))\n\(String(reflecting: value))"
    }

    @Test func nothingTheParserReturnsCarriesTheKeyItRead() throws {
        for fixture in KeyFixtures.all {
            let parsed = try KeyMaterialParser.parse(fixture.buffer)
            expectClean(renderings(of: parsed), "KeyMaterial for \(fixture.name)")
            expectClean(parsed.summary, "summary for \(fixture.name)")
        }
    }

    @Test func noRefusalCarriesWhatWasRefused() {
        let inputs = [
            KeyFixtures.publicKey, KeyFixtures.truncatedWithoutEndLine, KeyFixtures.truncatedBody,
            KeyFixtures.unreadableBody, KeyFixtures.ed25519Encrypted.text,
            KeyFixtures.rsa4096Plain.text,
        ]

        for input in inputs {
            do {
                _ = try KeyMaterialParser.parse(KeyMaterialBuffer(text: input))
            } catch let error as KeyMaterialError {
                expectClean(renderings(of: error), "thrown refusal")
                expectClean(renderings(of: error.copy), "refusal copy")
                expectClean(error.localizedDescription, "localizedDescription")
                expectClean(error.stateID, "stateID")
            } catch {
                Issue.record("a refusal that is not a KeyMaterialError: \(type(of: error))")
            }
        }
    }

    @Test func namingAFixtureInATestLogSaysOnlyWhichKeyItWas() {
        for fixture in KeyFixtures.all {
            #expect(fixture.testDescription == fixture.name)
            expectClean(fixture.testDescription, "test case name")
        }
    }

    @Test func theBufferSaysHowMuchItHoldsAndNeverWhat() {
        let buffer = KeyFixtures.rsa4096Plain.buffer

        expectClean(renderings(of: buffer), "buffer before zeroing")
        #expect(buffer.count == KeyFixtures.rsa4096Plain.text.utf8.count)
        #expect(!buffer.isZeroed)
    }

    @Test func zeroingOverwritesEveryByteAndIsIdempotent() {
        let buffer = KeyFixtures.ed25519Plain.buffer
        #expect(buffer.withBytes { $0.contains { $0 != 0 } })

        buffer.zero()
        buffer.zero()

        #expect(buffer.isZeroed)
        #expect(buffer.withBytes { $0.allSatisfy { $0 == 0 } })
        #expect(buffer.data().allSatisfy { $0 == 0 })
        expectClean(renderings(of: buffer), "buffer after zeroing")
    }

    @Test func aStoredKeyReachesTheKeychainAndNothingElseSeesIt() async throws {
        let backend = FakeKeychain()
        let store = KeychainSecretStore(backend: backend, authenticator: ScriptedGate(.authenticated))
        let reference = SecretReference(remoteID: RemoteID(rawValue: "import"), kind: .privateKey)
        let buffer = KeyFixtures.ed25519Plain.buffer

        try await store.store(buffer.data(), at: reference)
        buffer.zero()

        #expect(
            backend.payload(service: KeychainSchema.service, account: "privateKey.import")
                == Data(KeyFixtures.ed25519Plain.text.utf8)
        )
        expectClean(renderings(of: backend.stored), "enumerated items")
        expectClean(renderings(of: try backend.items(inService: KeychainSchema.service)), "items")
    }

    @Test func theHostFileWrittenAlongsideAnImportCarriesNoKey() async throws {
        let directory = TemporaryDirectory()
        defer { directory.remove() }

        let remote = Remote(
            id: RemoteID(rawValue: "import"),
            name: "Imported",
            host: "import.example.net",
            username: "keyuser"
        )
        try await FileRemoteStore(directory: directory.url).save(remote)

        expectClean(try directory.contents(), "store file")
    }
}
