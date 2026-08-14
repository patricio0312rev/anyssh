import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: AuthEnvironment.isAvailable))
struct AuthKeyTests {
    private let user = "keyuser"

    @Test func authenticatesWithAnEd25519Key() async throws {
        let session = try await AuthSupport.opened()
        try await session.authenticate(
            as: user,
            with: .privateKey(AuthSupport.key(AuthEnvironment.ed25519))
        )
        #expect(await session.isAuthenticated)
        await session.close()
    }

    @Test func authenticatesWithA4096BitRSAKey() async throws {
        let testbed = try #require(AuthEnvironment.testbed)
        #expect(!testbed.pubkeyAcceptedAlgorithms.contains("ssh-rsa"))
        #expect(testbed.pubkeyAcceptedAlgorithms.contains("rsa-sha2-256"))
        #expect(testbed.pubkeyAcceptedAlgorithms.contains("rsa-sha2-512"))

        let session = try await AuthSupport.opened()
        try await session.authenticate(as: user, with: .privateKey(AuthSupport.key(AuthEnvironment.rsa)))
        #expect(await session.isAuthenticated)
        await session.close()
    }

    @Test func authenticatesWithAnEncryptedKeyAndTheRightPassphrase() async throws {
        let credentials = try #require(AuthEnvironment.credentials)
        let session = try await AuthSupport.opened()
        try await session.authenticate(
            as: user,
            with: .privateKey(
                AuthSupport.key(AuthEnvironment.locked, passphrase: credentials.lockedKeyPassphrase)
            )
        )
        #expect(await session.isAuthenticated)
        await session.close()
    }

    @Test func reportsAWrongPassphraseAsItsOwnState() async throws {
        let credentials = try #require(AuthEnvironment.credentials)
        let session = try await AuthSupport.opened()
        let failure = await AuthSupport.failure(of: {
            try await session.authenticate(
                as: user,
                with: .privateKey(
                    AuthSupport.key(AuthEnvironment.locked, passphrase: credentials.wrongPassphrase)
                )
            )
        })

        #expect(failure?.stateID == "auth.wrongPassphrase")
        #expect(failure?.code == -19)
        #expect(await session.isAuthenticated == false)
        await session.close()
    }

    @Test func reportsAKeyTheHostDoesNotKnow() async throws {
        try #require(FileManager.default.isReadableFile(atPath: AuthEnvironment.unauthorised))
        let session = try await AuthSupport.opened()
        let failure = await AuthSupport.failure(of: {
            try await session.authenticate(
                as: user,
                with: .privateKey(AuthSupport.key(AuthEnvironment.unauthorised))
            )
        })

        #expect(failure?.stateID == "auth.publicKeyRejected")
        #expect(await session.isAuthenticated == false)
        await session.close()
    }

    @Test func offersOnlyPublicKeyForTheKeyAccount() async throws {
        let session = try await AuthSupport.opened()
        #expect(try await session.offeredMethods(for: user) == ["publickey"])
        await session.close()
    }
}
