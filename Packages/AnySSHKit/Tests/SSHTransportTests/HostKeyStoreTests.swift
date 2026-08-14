import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite struct HostKeyStoreTests {
    private let host = "trust.example"
    private let port = 22

    @Test func acceptWritesOneRecordAndASecondConnectDoesNotPrompt() async throws {
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)
        let answer = ScriptedTrustAnswer(.accept(remember: true))

        let first = try await trust(store, answer).evaluate(
            HostKeyFixture.ed25519, host: host, port: port)
        #expect(first == .accepted(remembered: true))
        #expect(answer.asked == 1)
        #expect(answer.lastStatus == .unknown)

        let second = try await trust(store, answer).evaluate(
            HostKeyFixture.ed25519, host: host, port: port)
        #expect(second == .alreadyKnown)
        #expect(answer.asked == 1)

        let stored = try await store.records()
        #expect(stored.count == 1)
        #expect(stored[0].key.raw == HostKeyFixture.ed25519.raw)
        #expect(directory.knownHostsText.split(separator: "\n").count == 1)
    }

    @Test func rejectWritesNoRecord() async throws {
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)
        let answer = ScriptedTrustAnswer(.reject)

        let outcome = try await trust(store, answer).evaluate(
            HostKeyFixture.ed25519, host: host, port: port)

        #expect(outcome == .refused(.rejected))
        #expect(outcome.failure?.stateID == "trust.rejected")
        #expect(try await store.knownKey(host: host, port: port) == nil)
        #expect(directory.knownHostsText.isEmpty)
    }

    @Test func cancelWritesNoRecordAndTheNextAttemptPromptsAgain() async throws {
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)
        let answer = ScriptedTrustAnswer(.cancel)

        let first = try await trust(store, answer).evaluate(
            HostKeyFixture.ed25519, host: host, port: port)
        #expect(first == .refused(.cancelled))
        #expect(first.failure?.stateID == "trust.cancelled")
        #expect(directory.knownHostsText.isEmpty)

        let second = try await trust(store, answer).evaluate(
            HostKeyFixture.ed25519, host: host, port: port)
        #expect(second == .refused(.cancelled))
        #expect(answer.asked == 2)
        #expect(answer.lastStatus == .unknown)
        #expect(try await store.knownKey(host: host, port: port) == nil)
    }

    @Test func acceptingWithoutRememberingWritesNothing() async throws {
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)
        let answer = ScriptedTrustAnswer(.accept(remember: false))

        let outcome = try await trust(store, answer).evaluate(
            HostKeyFixture.ed25519, host: host, port: port)

        #expect(outcome == .accepted(remembered: false))
        #expect(outcome.isTrusted)
        #expect(directory.knownHostsText.isEmpty)
    }

    @Test func recordsSurviveANewStoreOverTheSameDirectory() async throws {
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        try await FileHostKeyStore(directory: directory.url)
            .remember(HostKeyFixture.ed25519, host: host, port: port)

        let reopened = FileHostKeyStore(directory: directory.url)
        let recovered = try #require(try await reopened.knownKey(host: host, port: port))

        #expect(recovered.raw == HostKeyFixture.ed25519.raw)
        #expect(recovered.algorithm == .ed25519)
        #expect(recovered.matches(HostKeyFixture.ed25519))
    }

    @Test func theFileIsKnownHostsShapedAndKeyedByHostAndPort() async throws {
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)

        try await store.remember(HostKeyFixture.ed25519, host: host, port: 22)
        try await store.remember(HostKeyFixture.changed, host: host, port: 2222)

        let lines = directory.knownHostsText.split(separator: "\n").map(String.init)
        #expect(lines.count == 2)
        #expect(lines[0] == "trust.example ssh-ed25519 \(base64(HostKeyFixture.ed25519))")
        #expect(lines[1] == "[trust.example]:2222 ssh-ed25519 \(base64(HostKeyFixture.changed))")

        #expect(try await store.knownKey(host: host, port: 22)?.raw == HostKeyFixture.ed25519.raw)
        #expect(try await store.knownKey(host: host, port: 2222)?.raw == HostKeyFixture.changed.raw)
        #expect(try await store.knownKey(host: host, port: 2022) == nil)
        #expect(try await store.knownKey(host: "other.example", port: 22) == nil)
    }

    @Test func aLineWeCannotParseIsSkippedRatherThanGuessedAt() throws {
        #expect(KnownHostsRecord(line: "|1|hashed|pattern ssh-ed25519 AAAA") == nil)
        #expect(KnownHostsRecord(line: "@revoked host ssh-ed25519 AAAA") == nil)
        #expect(KnownHostsRecord(line: "*.example ssh-ed25519 AAAA") == nil)
        #expect(KnownHostsRecord(line: "# a comment") == nil)
        #expect(KnownHostsRecord(line: "host ssh-ed25519 not-base64!") == nil)
        #expect(KnownHostsRecord(line: "host ssh-rsa \(base64(HostKeyFixture.ed25519))") == nil)

        let line = try #require(KnownHostsRecord(host: host, port: 22, key: HostKeyFixture.rsa).line)
        let parsed = try #require(KnownHostsRecord(line: line))
        #expect(parsed.key.raw == HostKeyFixture.rsa.raw)
        #expect(parsed.host == host)
        #expect(parsed.port == 22)
    }

    @Test func concurrentWritesDoNotCorruptTheFile() async throws {
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let stores = (0..<4).map { _ in FileHostKeyStore(directory: directory.url) }

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<40 {
                group.addTask {
                    try? await stores[index % stores.count]
                        .remember(HostKeyFixture.ed25519, host: "host-\(index)", port: 22)
                }
            }
        }

        let reopened = FileHostKeyStore(directory: directory.url)
        let records = try await reopened.records()
        #expect(records.count == 40)
        #expect(Set(records.map(\.host)).count == 40)
        #expect(records.allSatisfy { $0.key.raw == HostKeyFixture.ed25519.raw })
    }

    @Test func forgettingRemovesOnlyThatHost() async throws {
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)
        try await store.remember(HostKeyFixture.ed25519, host: host, port: 22)
        try await store.remember(HostKeyFixture.changed, host: "other.example", port: 22)

        try await store.forget(host: host, port: 22)

        #expect(try await store.knownKey(host: host, port: 22) == nil)
        #expect(try await store.knownKey(host: "other.example", port: 22) != nil)
        #expect(try await FileHostKeyStore(directory: directory.url).records().count == 1)
    }

    private func trust(_ store: FileHostKeyStore, _ answer: ScriptedTrustAnswer) -> HostKeyTrust {
        HostKeyTrust(store: store, question: answer.question)
    }

    private func base64(_ key: HostKey) -> String {
        Data(key.raw).base64EncodedString()
    }
}
