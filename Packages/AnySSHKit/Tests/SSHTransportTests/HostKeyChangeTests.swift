import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite struct HostKeyChangeTests {
    private let host = "trust.example"
    private let port = 22

    @Test func aChangedKeyIsRefusedAndTheStoredRecordSurvives() async throws {
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)
        try await store.remember(HostKeyFixture.ed25519, host: host, port: port)
        let answer = ScriptedTrustAnswer(.cancel)

        let outcome = try await HostKeyTrust(store: store, question: answer.question)
            .evaluate(HostKeyFixture.changed, host: host, port: port)

        #expect(outcome == .refused(.hostKeyChanged))
        #expect(outcome.failure?.stateID == "trust.hostKeyChanged")
        #expect(!outcome.isTrusted)
        #expect(try await store.knownKey(host: host, port: port)?.raw == HostKeyFixture.ed25519.raw)
        #expect(try await FileHostKeyStore(directory: directory.url).records().count == 1)
    }

    @Test func theQuestionCarriesTheStoredFingerprint() async throws {
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)
        try await store.remember(HostKeyFixture.ed25519, host: host, port: port)
        let answer = ScriptedTrustAnswer(.cancel)

        _ = try await HostKeyTrust(store: store, question: answer.question)
            .evaluate(HostKeyFixture.changed, host: host, port: port)

        #expect(answer.asked == 1)
        #expect(answer.lastStatus == .changed(stored: HostKeyFixture.ed25519.fingerprint))
    }

    @Test func acceptingAChangedKeyIsNotHonoured() async throws {
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)
        try await store.remember(HostKeyFixture.ed25519, host: host, port: port)

        for verdict in [HostKeyVerdict.accept(remember: true), .accept(remember: false), .reject] {
            let answer = ScriptedTrustAnswer(verdict)
            let outcome = try await HostKeyTrust(store: store, question: answer.question)
                .evaluate(HostKeyFixture.changed, host: host, port: port)

            #expect(outcome == .refused(.hostKeyChanged))
            #expect(try await store.knownKey(host: host, port: port)?.raw == HostKeyFixture.ed25519.raw)
        }
    }

    @Test func forgettingMakesTheNextAttemptAFirstUse() async throws {
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)
        try await store.remember(HostKeyFixture.ed25519, host: host, port: port)
        let answer = ScriptedTrustAnswer(.accept(remember: true))
        let trust = HostKeyTrust(store: store, question: answer.question)

        #expect(
            try await trust.evaluate(HostKeyFixture.changed, host: host, port: port)
                == .refused(.hostKeyChanged))
        try await store.forget(host: host, port: port)
        #expect(try await trust.status(of: HostKeyFixture.changed, host: host, port: port) == .unknown)

        let retried = try await trust.evaluate(HostKeyFixture.changed, host: host, port: port)
        #expect(retried == .accepted(remembered: true))
        #expect(try await store.knownKey(host: host, port: port)?.raw == HostKeyFixture.changed.raw)
        #expect(answer.asked == 2)
    }

    @Test func aMatchingKeyAsksNobody() async throws {
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)
        try await store.remember(HostKeyFixture.ed25519, host: host, port: port)
        let answer = ScriptedTrustAnswer(.reject)

        let outcome = try await HostKeyTrust(store: store, question: answer.question)
            .evaluate(HostKeyFixture.ed25519, host: host, port: port)

        #expect(outcome == .alreadyKnown)
        #expect(answer.asked == 0)
    }
}
