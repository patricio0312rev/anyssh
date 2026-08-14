import Darwin
import Foundation
import Testing

@testable import SSHTransport

@Suite struct SessionSocketTests {
    @Test(
        arguments: [
            (Duration.seconds(Int64.max), Int32.max),
            (Duration.seconds(Int64.min), Int32(0)),
            (Duration.seconds(Int64.max / 1000), Int32.max),
            (Duration.seconds(10), Int32(10_000)),
            (Duration.milliseconds(250), Int32(250)),
            (Duration.zero, Int32(0)),
            (Duration.seconds(-5), Int32(0)),
        ])
    func scalesToMillisecondsWithoutOverflowing(duration: Duration, milliseconds: Int32) {
        #expect(SessionSocket.milliseconds(duration) == milliseconds)
    }

    @Test(
        arguments: [
            Duration.microseconds(500),
            Duration.microseconds(1),
            Duration.nanoseconds(1),
        ])
    func roundsAWaitShorterThanAMillisecondUpRatherThanToNothing(duration: Duration) {
        #expect(SessionSocket.milliseconds(duration) == 1)
    }

    @Test func readsTheTwoDirectionsApart() {
        #expect(SocketReadiness(revents: Int16(POLLOUT)) == SocketReadiness(writable: true))
        #expect(SocketReadiness(revents: Int16(POLLIN)) == SocketReadiness(readable: true))
        #expect(
            SocketReadiness(revents: Int16(POLLIN) | Int16(POLLOUT))
                == SocketReadiness(readable: true, writable: true))
        #expect(SocketReadiness(revents: Int16(POLLHUP)) == SocketReadiness())
    }

    @Test func aWaitThatExpiresReportsNeitherDirection() async throws {
        let listener = try #require(LocalListener(host: "127.0.0.1"))
        defer { listener.close() }
        let addresses = try AddressResolver.resolve(host: "127.0.0.1", port: listener.port)
        let result = try await SessionSocket.dial(addresses, host: "127.0.0.1", timeout: .seconds(5))
        defer { SessionSocket.close(result.descriptor) }

        let readiness = await SessionSocket.waitUntilReady(
            result.descriptor,
            wantsRead: true,
            wantsWrite: false,
            timeout: .milliseconds(50)
        )

        #expect(readiness == SocketReadiness())
    }
}
