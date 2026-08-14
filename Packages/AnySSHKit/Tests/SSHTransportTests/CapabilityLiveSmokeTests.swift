import Testing

@testable import SSHTransport

@Suite(.enabled(if: LiveHost.isDevelopmentHostReachable))
struct CapabilityLiveSmokeTests {
    @Test func loginShellProbeUsesOneChannelAndRecordsTheFullResult() async throws {
        let counter = CapabilityRoundTripCounter()
        let probe = SSHCapabilityProbe(
            runner: LiveCapabilityBatchRunner(host: .development, counter: counter)
        )
        let value = try await probe.probe()

        #expect(counter.value == 1)
        try LiveArtifact.write(
            "live-p31.json",
            liveCapabilityDictionary(value).merging(
                ["roundTrips": counter.value, "host": LiveHost.development.host],
                uniquingKeysWith: { first, _ in first }
            )
        )
    }
}
