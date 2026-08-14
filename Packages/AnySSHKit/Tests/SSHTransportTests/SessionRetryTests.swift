import CSSH
import Foundation
import Testing

@testable import SSHTransport

@Suite struct SessionRetryTests {
    @Test func anEagainIsAnInstructionToCallAgain() async throws {
        let listener = try #require(LocalListener(host: "127.0.0.1"))
        defer { listener.close() }
        let session = try await SessionRetryTests.started(on: listener)

        let answers = ScriptedAnswers([LIBSSH2_ERROR_EAGAIN, LIBSSH2_ERROR_EAGAIN, 0])
        let result = try await session.retryingScripted(answers)

        #expect(result == 0)
        #expect(answers.calls == 3)
        #expect(await session.diagnostics.eagainRetries == 2)
        #expect(await session.diagnostics.errorCodes.isEmpty)
        await session.close()
    }

    @Test func aRealFailureIsReturnedAndRecorded() async throws {
        let listener = try #require(LocalListener(host: "127.0.0.1"))
        defer { listener.close() }
        let session = try await SessionRetryTests.started(on: listener)

        let answers = ScriptedAnswers([LIBSSH2_ERROR_EAGAIN, LIBSSH2_ERROR_SOCKET_SEND])
        let result = try await session.retryingScripted(answers)

        #expect(result == LIBSSH2_ERROR_SOCKET_SEND)
        #expect(answers.calls == 2)
        #expect(await session.diagnostics.errorCodes == [LIBSSH2_ERROR_SOCKET_SEND])
        await session.close()
    }

    @Test func anEndlessEagainStopsAtItsDeadline() async throws {
        let listener = try #require(LocalListener(host: "127.0.0.1"))
        defer { listener.close() }
        let session = try await SessionRetryTests.started(on: listener)

        let window = Duration.seconds(1)
        let answers = ScriptedAnswers([], repeating: LIBSSH2_ERROR_EAGAIN)
        await #expect(throws: TransportFailure.keepaliveTimeout) {
            try await session.retryingScripted(answers, deadline: .now + window)
        }

        let waits = await session.diagnostics.eagainRetries
        #expect(waits >= 1)
        #expect(waits <= Int(window / SSHSession.waitSlice) + 4, "waited \(waits) slices")
        await session.close()
    }

    private static func started(on listener: LocalListener) async throws -> SSHSession {
        let session = SSHSession(target: SessionTarget(host: "127.0.0.1", port: listener.port))
        try await session.dial()
        try await session.startSession()
        return session
    }
}

final class ScriptedAnswers: @unchecked Sendable {
    private let lock = NSLock()
    private var answers: [Int32]
    private let fallback: Int32?
    private var made = 0

    init(_ answers: [Int32], repeating fallback: Int32? = nil) {
        self.answers = answers
        self.fallback = fallback
    }

    var calls: Int {
        lock.withLock { made }
    }

    func next() -> Int32 {
        lock.withLock {
            made += 1
            guard !answers.isEmpty else { return fallback ?? 0 }
            return answers.removeFirst()
        }
    }
}

extension SSHSession {
    func retryingScripted(
        _ answers: ScriptedAnswers,
        deadline: ContinuousClock.Instant? = nil
    ) async throws -> Int32 {
        try await retrying(deadline: deadline) { _ in answers.next() }
    }
}
