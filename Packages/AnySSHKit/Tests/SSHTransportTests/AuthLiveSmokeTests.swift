import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: LiveHost.isDevelopmentHostReachable))
struct AuthLiveSmokeTests {
    @Test func authenticatesToTheDevelopmentHostAndRecordsTheMethod() async throws {
        let host = LiveHost.development
        let session = SSHSession(
            target: SessionTarget(host: host.host, port: Int(host.port)),
            configuration: AuthSupport.patient,
            trust: TestTrust.acceptingFirstUse()
        )
        try await LiveSetupRetry.run { try await session.open() }

        let offered = try await session.offeredMethods(for: host.username)
        try await session.authenticate(
            as: host.username,
            with: .privateKey(AuthSupport.key(host.privateKeyPath))
        )

        #expect(await session.isAuthenticated)
        try LiveArtifact.write(
            "live-p11.json",
            [
                "host": host.host,
                "user": host.username,
                "offeredMethods": offered,
                "negotiatedMethod": "publickey",
                "keyAlgorithm": Self.algorithm(of: host.publicKeyPath),
                "banner": await session.remoteBanner ?? "",
            ]
        )
        await session.close()
    }

    private static func algorithm(of publicKeyPath: String) -> String {
        guard let contents = try? String(contentsOfFile: publicKeyPath, encoding: .utf8) else {
            return "unknown"
        }
        return contents.split(separator: " ").first.map(String.init) ?? "unknown"
    }
}
