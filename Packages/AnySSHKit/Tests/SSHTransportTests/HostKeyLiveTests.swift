import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: TestbedHost.isDevelopmentHostReachable))
struct HostKeyLiveTests {
    @Test func acceptingOnceIsEnoughForTheNextConnection() async throws {
        let host = TestbedHost.development
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)
        let answer = ScriptedTrustAnswer(.accept(remember: true))
        let trust = HostKeyTrust(store: store, question: answer.question)
        let target = SessionTarget(host: host.host, port: Int(host.port))

        let first = SSHSession(target: target, trust: trust)
        let accepted = try await LiveSetupRetry.run { try await first.open() }
        let offered = try #require(await first.negotiatedHostKey)
        let libssh2Digest = try #require(await first.negotiatedHostKeyDigest)
        #expect(await first.state == .connected)
        await first.close()

        #expect(accepted == .accepted(remembered: true))
        #expect(answer.asked == 1)
        #expect(offered.fingerprint.digest == libssh2Digest)

        let second = SSHSession(target: target, trust: trust)
        #expect(try await second.open() == .alreadyKnown)
        #expect(answer.asked == 1)
        #expect(await second.trustOutcome == .alreadyKnown)
        await second.close()

        try LiveArtifact.write(
            "live-p10.json",
            [
                "host": host.host,
                "port": Int(host.port),
                "algorithm": offered.typeName,
                "fingerprint": offered.fingerprint.openSSH,
                "fingerprintHex": offered.fingerprint.hex,
                "agreesWithLibssh2Digest": offered.fingerprint.digest == libssh2Digest,
                "storedLine": await store.records().first?.line ?? "",
                "promptsForTwoConnections": answer.asked,
                "recordedAt": ISO8601DateFormatter().string(from: Date()),
            ]
        )
    }
}
