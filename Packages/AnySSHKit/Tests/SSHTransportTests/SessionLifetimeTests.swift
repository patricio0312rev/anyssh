import CSSH
import Foundation
import Testing

@testable import SSHTransport

@Suite struct SessionLifetimeTests {
    @Test func closingWhileTheLoopWaitsRefusesInsteadOfUsingTheFreedHandle() async throws {
        let listener = try #require(LocalListener(host: "127.0.0.1"))
        defer { listener.close() }

        let session = SSHSession(
            target: SessionTarget(host: "127.0.0.1", port: listener.port),
            configuration: SSHSessionConfiguration(handshakeTimeout: .seconds(600))
        )
        try await session.dial()
        let generation = await session.generation

        let handshake = Task { try await session.exchangeKeys() }
        try #require(await session.waitUntilWaitingOnTheSocket(), "the loop never reached a wait")

        await session.close()

        await #expect(throws: TransportFailure.notConnected) { try await handshake.value }
        #expect(await session.state == .disconnected(.closedByUser))
        #expect(await session.isDialled == false)
        #expect(await session.stillHolds(generation) == false)
    }

    @Test func aSecondDialDoesNotAdoptTheFirstAttemptsRetries() async throws {
        let listener = try #require(LocalListener(host: "127.0.0.1"))
        defer { listener.close() }

        let session = SSHSession(target: SessionTarget(host: "127.0.0.1", port: listener.port))
        try await session.dial()
        let first = await session.generation

        try await session.dial()

        #expect(await session.generation != first)
        #expect(await session.stillHolds(first) == false)
        await session.close()
    }

    @Test func aSocketThatArrivesAfterACloseIsClosedRatherThanAdopted() async throws {
        let listener = try #require(LocalListener(host: "127.0.0.1"))
        defer { listener.close() }

        let session = SSHSession(target: SessionTarget(host: "127.0.0.1", port: listener.port))
        try await session.dial()
        let generation = await session.generation
        await session.close()

        let addresses = try AddressResolver.resolve(host: "127.0.0.1", port: listener.port)
        let late = try await SessionSocket.dial(
            addresses, host: "127.0.0.1", timeout: .seconds(5))

        #expect(await session.adopt(late, from: generation) == false)
        #expect(await session.isDialled == false)
        #expect(
            !PosixSocket.isConnected(late.descriptor, toPort: listener.port),
            "the late socket was left open"
        )
    }

    @Test func writableReadinessIsNotEvidenceThatThePeerSpoke() async throws {
        let listener = try #require(LocalListener(host: "127.0.0.1"))
        defer { listener.close() }

        let session = SSHSession(target: SessionTarget(host: "127.0.0.1", port: listener.port))
        try await session.dial()
        let before = await session.lastInbound

        try await session.waitForSocket(
            deadline: nil,
            directions: LIBSSH2_SESSION_BLOCK_OUTBOUND
        )

        #expect(await session.lastInbound == before)
        await session.close()
    }

    @Test func readableReadinessIsEvidenceThatThePeerSpoke() async throws {
        let listener = try #require(LocalListener(host: "127.0.0.1"))
        defer { listener.close() }

        let session = SSHSession(target: SessionTarget(host: "127.0.0.1", port: listener.port))
        try await session.dial()
        try #require(listener.speak([0x41]), "the listener never accepted the connection")
        let before = await session.lastInbound

        try await session.waitForSocket(
            deadline: nil,
            directions: LIBSSH2_SESSION_BLOCK_INBOUND
        )

        #expect(await session.lastInbound > before)
        await session.close()
    }
}

extension SSHSession {
    func stillHolds(_ generation: Int) -> Bool {
        (try? liveHandle(of: generation)) != nil
    }

    func waitUntilWaitingOnTheSocket(withinYields ceiling: Int = 10_000) async -> Bool {
        for _ in 0..<ceiling {
            if diagnostics.eagainRetries > 0 { return true }
            await Task.yield()
        }
        return diagnostics.eagainRetries > 0
    }
}
