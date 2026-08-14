import AnySSHCore
import CSSH
import Darwin
import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: AvailableSSHHost.isAvailable))
struct HostKeyGateTests {
    @Test func aSessionWithNoTrustPolicyRefusesTheHostItReached() async throws {
        let endpoint = try #require(AvailableSSHHost.endpoint)
        let session = SSHSession(
            target: SessionTarget(host: endpoint.host, port: endpoint.port))

        let refusal = await #expect(throws: TransportFailure.self) { try await session.open() }

        #expect(refusal?.stateID == "trust.cancelled")
        #expect(await session.state == .disconnected(.failed(stateID: "trust.cancelled")))
        #expect(await session.isDialled == false)
        #expect(await session.trustOutcome == nil)
    }

    @Test func aChangedKeyRefusesThroughTheOrdinaryEntryPoint() async throws {
        let endpoint = try #require(AvailableSSHHost.endpoint)
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)
        try await store.remember(HostKeyFixture.changed, host: endpoint.host, port: endpoint.port)

        let answer = ScriptedTrustAnswer(.accept(remember: true))
        let session = SSHSession(
            target: SessionTarget(host: endpoint.host, port: endpoint.port),
            trust: HostKeyTrust(store: store, question: answer.question)
        )

        let refusal = await #expect(throws: TransportFailure.self) { try await session.open() }

        #expect(refusal?.stateID == "trust.hostKeyChanged")
        #expect(await session.state == .disconnected(.failed(stateID: "trust.hostKeyChanged")))
        #expect(await session.isDialled == false)
        #expect(answer.lastStatus == .changed(stored: HostKeyFixture.changed.fingerprint))
        #expect(
            try await store.knownKey(host: endpoint.host, port: endpoint.port)?.raw
                == HostKeyFixture.changed.raw)
    }

    @Test func decidingTrustSendsNothing() async throws {
        let endpoint = try #require(AvailableSSHHost.endpoint)
        let counter = SSHIOContext(GateByteCounter())
        let directory = HostKeyTempDirectory()
        defer { directory.remove() }
        let store = FileHostKeyStore(directory: directory.url)
        try await store.remember(HostKeyFixture.changed, host: endpoint.host, port: endpoint.port)

        let answer = ScriptedTrustAnswer(.accept(remember: true))
        let trust = HostKeyTrust(store: store, question: answer.question)
        let session = SSHSession(
            target: SessionTarget(host: endpoint.host, port: endpoint.port),
            configuration: SSHSessionConfiguration(
                io: SSHIOCallbacks(receive: gateReceive, send: gateSend, context: counter)
            ),
            trust: trust
        )
        try await session.dial()
        try await session.exchangeKeys()

        let afterKeyExchange = counter.value.sent
        #expect(afterKeyExchange > 0)
        #expect(await session.state == .connecting, "the key exchange reported a connection")

        let refusal = await #expect(throws: TransportFailure.self) {
            try await session.verifyHostKey(trust)
        }

        #expect(refusal?.stateID == "trust.hostKeyChanged")
        #expect(counter.value.sent == afterKeyExchange)
        #expect(answer.asked == 1)
        await session.close()
    }
}

struct GateByteCounter {
    var sent = 0
    var received = 0
}

let gateReceive: SSHIOCallbacks.Receive = { socket, buffer, length, flags, abstract in
    let result = recv(socket, buffer, length, flags)
    if result > 0, let counter = GateByteCounter.bound(abstract) {
        counter.pointee.received += result
    }
    return result < 0 ? -Int(errno) : result
}

let gateSend: SSHIOCallbacks.Send = { socket, buffer, length, flags, abstract in
    let result = send(socket, buffer, length, flags)
    if result > 0, let counter = GateByteCounter.bound(abstract) { counter.pointee.sent += result }
    return result < 0 ? -Int(errno) : result
}

extension GateByteCounter {
    static func bound(
        _ abstract: UnsafeMutablePointer<UnsafeMutableRawPointer?>?
    ) -> UnsafeMutablePointer<GateByteCounter>? {
        abstract?.pointee?.assumingMemoryBound(to: GateByteCounter.self)
    }
}
