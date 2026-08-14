import AnySSHCore
import Fixtures
import Foundation
import Testing

@testable import AnySSHMocks

@Suite struct HostKeyScenarioTests {
    private let host = HostKeyFixtures.host
    private let port = HostKeyFixtures.port

    @Test func anUnknownHostKnowsNothing() async throws {
        let store = HostKeyFixtures.store(.unknownHost)

        #expect(try await store.knownKey(host: host, port: port) == nil)
        #expect(await store.wroteNothing)
    }

    @Test func aKnownAndMatchingHostAnswersTheSameBytes() async throws {
        let store = HostKeyFixtures.store(.knownAndMatching(HostKeyFixtures.stored))

        let stored = try #require(try await store.knownKey(host: host, port: port))
        #expect(stored.raw == HostKeyFixtures.stored.raw)
        #expect(stored.algorithm == .ed25519)
    }

    @Test func aKnownAndChangedHostAnswersDifferentBytesFromTheOfferedKey() async throws {
        let store = HostKeyFixtures.store(.knownAndChanged(stored: HostKeyFixtures.stored))

        let stored = try #require(try await store.knownKey(host: host, port: port))
        #expect(stored.raw != HostKeyFixtures.offered.raw)
        #expect(!HostKeyFixtures.stored.raw.isEmpty)
    }

    @Test func everyWriteIsRecordedSoARefusalCanBeProvedToWriteNothing() async throws {
        let store = HostKeyFixtures.store(.unknownHost)

        try await store.remember(HostKeyFixtures.offered, host: host, port: port)
        #expect(await store.writes == [.remembered(HostKeyFixtures.offered, host: host, port: port)])
        #expect(try await store.knownKey(host: host, port: port)?.raw == HostKeyFixtures.offered.raw)

        try await store.forget(host: host, port: port)
        #expect(await store.writes.count == 2)
        #expect(try await store.knownKey(host: host, port: port) == nil)
    }

    @Test func aStoreIsKeyedByHostAndPort() async throws {
        let store = ScriptedHostKeyStore(keys: [host: HostKeyFixtures.stored], port: 22)

        #expect(try await store.knownKey(host: host, port: 22) != nil)
        #expect(try await store.knownKey(host: host, port: 2222) == nil)
    }

    @Test func theMockKeysAreTheCheckedInFixtureBytes() throws {
        #expect(HostKeyFixtures.stored.raw == blob("hostkeys/ed25519.pub"))
        #expect(HostKeyFixtures.offered.raw == blob("hostkeys/ed25519-changed.pub"))
        #expect(HostKeyFixtures.scenarios.count == 3)
    }

    private func blob(_ path: String) -> [UInt8] {
        guard let text = try? String(contentsOf: FixtureBundle.url(path), encoding: .utf8),
            let encoded = text.split(separator: " ").dropFirst().first,
            let raw = Data(base64Encoded: String(encoded))
        else { return [] }
        return Array(raw)
    }
}
