import AnySSHCore
import Foundation

@testable import SSHTransport

enum AuthSupport {
    static let patient = SSHSessionConfiguration(
        handshakeTimeout: .seconds(3600),
        deadPeerTimeout: .seconds(3600)
    )

    static func opened() async throws -> SSHSession {
        try await LiveSetupRetry.run {
            let testbed = AuthEnvironment.testbed
            let session = SSHSession(
                target: SessionTarget(
                    host: testbed?.host ?? TestbedHost.sshd.host,
                    port: testbed?.port ?? Int(TestbedHost.sshd.port)
                ),
                configuration: patient,
                trust: TestTrust.acceptingFirstUse()
            )
            try await session.open()
            return session
        }
    }

    static func key(_ path: String, passphrase: String? = nil) -> AuthPrivateKey {
        AuthPrivateKey(
            privateKey: (try? Data(contentsOf: URL(fileURLWithPath: path))) ?? Data(),
            publicKey: try? Data(contentsOf: URL(fileURLWithPath: path + ".pub")),
            passphrase: passphrase
        )
    }

    static func failure(of work: () async throws -> Void) async -> AuthFailure? {
        do {
            try await work()
            return nil
        } catch let failure as AuthFailure {
            return failure
        } catch {
            return AuthFailure(stateID: "test.unexpectedError", detail: "\(error)")
        }
    }
}
