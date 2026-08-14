import CSSH
import Darwin
import Foundation
import Testing

@testable import SSHTransport

private struct EagainInjection {
    var remaining: Int
    var remainingSends = 0
    var injected = 0
    var passedThrough = 0
}

private let injectedReceive: SSHIOCallbacks.Receive = { socket, buffer, length, flags, abstract in
    if let injection = EagainInjection.bound(abstract), injection.pointee.consume() {
        return -Int(EAGAIN)
    }
    return EagainInjection.errnoCoded(recv(socket, buffer, length, flags))
}

private let injectedSend: SSHIOCallbacks.Send = { socket, buffer, length, flags, abstract in
    if let injection = EagainInjection.bound(abstract), injection.pointee.consumeSend() {
        return -Int(EAGAIN)
    }
    return EagainInjection.errnoCoded(send(socket, buffer, length, flags))
}

extension EagainInjection {
    fileprivate mutating func consumeSend() -> Bool {
        guard remainingSends > 0 else { return consume() }
        remainingSends -= 1
        injected += 1
        return true
    }

    fileprivate mutating func consume() -> Bool {
        guard remaining > 0 else {
            passedThrough += 1
            return false
        }
        remaining -= 1
        injected += 1
        return true
    }

    fileprivate static func bound(
        _ abstract: UnsafeMutablePointer<UnsafeMutableRawPointer?>?
    ) -> UnsafeMutablePointer<EagainInjection>? {
        abstract?.pointee?.assumingMemoryBound(to: EagainInjection.self)
    }

    fileprivate static func errnoCoded(_ result: Int) -> Int {
        result < 0 ? -Int(errno) : result
    }
}

@Suite(.enabled(if: AvailableSSHHost.isAvailable))
struct SessionEagainTests {
    @Test func handshakeCompletesAfterTwoHundredEagainAnswers() async throws {
        let endpoint = try #require(AvailableSSHHost.endpoint)
        let injection = SSHIOContext(EagainInjection(remaining: 200))

        var configuration = AuthSupport.patient
        configuration.io = SSHIOCallbacks(
            receive: injectedReceive,
            send: injectedSend,
            context: injection
        )
        let session = SSHSession(
            target: SessionTarget(host: endpoint.host, port: endpoint.port),
            configuration: configuration,
            trust: TestTrust.acceptingFirstUse()
        )

        try await session.open()

        #expect(injection.value.injected == 200)
        #expect(injection.value.remaining == 0)
        #expect(injection.value.passedThrough > 0)
        #expect(await session.remoteBanner?.hasPrefix("SSH-2.0-") == true)
        #expect(await session.state == .connected)
        #expect(await session.diagnostics.errorCodes.isEmpty)
        #expect(await session.diagnostics.eagainRetries >= 200)
        await session.close()
    }

    @Test func anEagainFromTheKeepaliveIsNotReportedAsConnectionLoss() async throws {
        let endpoint = try #require(AvailableSSHHost.endpoint)
        let injection = SSHIOContext(EagainInjection(remaining: 0))

        var configuration = AuthSupport.patient
        configuration.keepaliveInterval = .seconds(1)
        configuration.io = SSHIOCallbacks(
            receive: injectedReceive,
            send: injectedSend,
            context: injection
        )
        let session = SSHSession(
            target: SessionTarget(host: endpoint.host, port: endpoint.port),
            configuration: configuration,
            trust: TestTrust.acceptingFirstUse()
        )
        try await session.open()

        injection.withValue { $0.remainingSends = 1 }

        let budget = try await session.sendKeepalive()

        #expect(budget > .zero)
        #expect(injection.value.remainingSends == 0, "the keepalive never reached the socket")
        #expect(injection.value.injected == 1)
        #expect(await session.state == .connected)
        #expect(await session.diagnostics.errorCodes.isEmpty)

        #expect(try await session.sendKeepalive() > .zero)
        await session.close()
    }
}
