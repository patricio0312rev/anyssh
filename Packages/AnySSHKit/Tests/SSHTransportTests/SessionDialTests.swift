import Darwin
import Foundation
import Testing

@testable import SSHTransport

@Suite struct SessionDialTests {
    @Test func takesTheIPv6PathToALoopbackListener() async throws {
        let listener = try #require(LocalListener(host: "::1"))
        defer { listener.close() }

        let session = SSHSession(target: SessionTarget(host: "::1", port: listener.port))
        try await session.dial()
        let address = try #require(await session.resolvedAddress)
        #expect(address.family == AF_INET6)
        #expect(address.familyName == "AF_INET6")
        #expect(address.literal == "::1")
        #expect(address.isIPv6)
        await session.close()
    }

    @Test func takesTheIPv4PathWhenThatIsWhatTheHostOffers() async throws {
        let listener = try #require(LocalListener(host: "127.0.0.1"))
        defer { listener.close() }

        let session = SSHSession(target: SessionTarget(host: "127.0.0.1", port: listener.port))
        try await session.dial()
        let address = try #require(await session.resolvedAddress)
        #expect(address.family == AF_INET)
        #expect(address.familyName == "AF_INET")
        #expect(!address.isIPv6)
        await session.close()
    }

    @Test func triesEveryResolvedAddressUntilOneAnswers() async throws {
        let listener = try #require(LocalListener(host: "127.0.0.1"))
        defer { listener.close() }

        let families = try AddressResolver.resolve(host: "localhost", port: listener.port)
            .map(\.familyName)
        try #require(Set(families).count > 1, "localhost resolved to one family only: \(families)")

        let session = SSHSession(target: SessionTarget(host: "localhost", port: listener.port))
        try await session.dial()
        #expect(await session.resolvedAddress?.family == AF_INET)
        await session.close()
    }

    @Test func fallsBackToTheStoredAddressWhenTheNameDoesNotResolve() async throws {
        let listener = try #require(LocalListener(host: "127.0.0.1"))
        defer { listener.close() }

        let session = SSHSession(
            target: SessionTarget(
                host: "anyssh-magicdns-absent.invalid",
                port: listener.port,
                fallbackAddress: "127.0.0.1"
            )
        )
        try await session.dial()
        #expect(await session.notes.map(\.stateID) == ["transport.dnsFallback"])
        #expect(await session.resolvedAddress?.literal == "127.0.0.1")
        await session.close()
    }

    @Test func reportsADialFailureWithItsErrorState() async {
        let session = SSHSession(
            target: SessionTarget(host: "127.0.0.1", port: 1),
            configuration: SSHSessionConfiguration(connectTimeout: .seconds(2))
        )
        await #expect(throws: TransportFailure.self) { try await session.dial() }
        #expect(await session.state == .disconnected(.failed(stateID: "transport.dialFailed")))
    }

    @Suite(.enabled(if: TestbedHost.isReachable))
    struct Testbed {
        @Test func reachesTheBannerExchangeOnTheTestbed() async throws {
            let session = SSHSession(
                target: SessionTarget(host: TestbedHost.sshd.host, port: Int(TestbedHost.sshd.port)),
                trust: TestTrust.acceptingFirstUse()
            )
            try await session.open()

            let banner = try #require(await session.remoteBanner)
            #expect(banner.hasPrefix("SSH-2.0-"))
            #expect(await session.state == .connected)
            #expect(await session.diagnostics.errorCodes.isEmpty)
            await session.close()
        }
    }
}
