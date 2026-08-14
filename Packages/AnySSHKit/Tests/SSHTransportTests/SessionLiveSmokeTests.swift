import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: TestbedHost.isDevelopmentHostReachable))
struct SessionLiveSmokeTests {
    @Test func dialsTheDevelopmentHostAndRecordsWhatItFound() async throws {
        let host = TestbedHost.development
        let session = SSHSession(
            target: SessionTarget(host: host.host, port: Int(host.port)),
            trust: TestTrust.acceptingFirstUse()
        )

        let start = ContinuousClock.now
        try await session.open()
        let handshake = start.duration(to: .now)

        let banner = try #require(await session.remoteBanner)
        #expect(!banner.isEmpty)

        let address = await session.resolvedAddress
        try LiveArtifact.write(
            "live-p9.json",
            [
                "host": host.host,
                "port": Int(host.port),
                "addressFamily": address?.familyName ?? "unknown",
                "address": address?.literal ?? "",
                "connectRoundTripMilliseconds": await session.connectRoundTrip?.milliseconds ?? -1,
                "handshakeMilliseconds": handshake.milliseconds,
                "banner": banner,
                "eagainRetries": await session.diagnostics.eagainRetries,
                "recordedAt": ISO8601DateFormatter().string(from: Date()),
            ]
        )
        await session.close()
    }
}

extension Duration {
    var milliseconds: Int {
        Int(components.seconds * 1000 + components.attoseconds / 1_000_000_000_000_000)
    }
}
