import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite struct CapabilityCacheTests {
    private let remote = RemoteID(rawValue: "cache-test")

    @Test func cacheUsesTTLRefreshAndReconnectInvalidation() async throws {
        let value = try CapabilityParser().parse(CapabilityFixtureData.gitOnly)
        let probe = CountingCapabilityProbe(value: value)
        let cache = CapabilityCache(ttl: 60)
        let start = Date(timeIntervalSince1970: 100)

        _ = try await cache.capabilities(for: remote, using: probe, run: passthrough, at: start)
        _ = try await cache.capabilities(
            for: remote,
            using: probe,
            run: passthrough,
            at: start.addingTimeInterval(1)
        )
        #expect(probe.calls == 1)
        _ = try await cache.refresh(
            remoteID: remote,
            using: probe,
            run: passthrough,
            at: start.addingTimeInterval(2)
        )
        #expect(probe.calls == 2)

        await cache.invalidateOnReconnect(remoteID: remote)
        #expect(await cache.cached(for: remote, at: start.addingTimeInterval(3)) == nil)
    }

    @Test func expiredEntriesAreNotReturned() async throws {
        let value = try CapabilityParser().parse(CapabilityFixtureData.oldGit)
        let probe = CountingCapabilityProbe(value: value)
        let cache = CapabilityCache(ttl: 10)
        let start = Date(timeIntervalSince1970: 200)

        _ = try await cache.capabilities(for: remote, using: probe, run: passthrough, at: start)
        #expect(await cache.cached(for: remote, at: start.addingTimeInterval(10)) == nil)
    }

    private func passthrough(
        _ operation: @escaping @Sendable () async throws -> HostCapabilities
    ) async throws -> HostCapabilities {
        try await operation()
    }
}
