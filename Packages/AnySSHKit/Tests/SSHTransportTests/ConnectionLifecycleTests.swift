import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite struct ConnectionLifecycleTests {
    @Test func aFreshConnectionHasDialledNothing() async {
        let connection = ConnectionTestbed.connection()

        #expect(await connection.displayState == .idle)
        #expect(await connection.controlState == .idle)
        #expect(await connection.openChannelCount == 0)
        #expect(await connection.inFlightControlCount == 0)
        #expect(await connection.notes.isEmpty)
    }

    @Test func cancellingANeverDialledConnectionIsSafe() async {
        let connection = ConnectionTestbed.connection()

        await connection.cancelAll(reason: .cancelledBySwitch)
        await connection.cancelAll(reason: .cancelledBySwitch)

        #expect(await connection.cancellations == 2)
        #expect(await connection.lastCancellationReason == .cancelledBySwitch)
        #expect(await connection.openChannelCount == 0)
    }

    @Test func aClosedConnectionRefusesFurtherWork() async throws {
        let connection = ConnectionTestbed.connection()
        await connection.close(reason: .closedByUser)

        let failure = await ConnectionTestbed.failure {
            _ = try await connection.run(ConnectionTestbed.batch("late", ["true"]))
        }

        #expect(failure?.stateID == TransportFailure.connectionClosed.stateID)
        #expect(await connection.displayState == .disconnected(.closedByUser))
        #expect(await connection.controlState == .disconnected(.closedByUser))
    }

    @Test func aDisplayWithNoSinkRefusesToStart() async {
        let connection = ConnectionTestbed.connection()

        let failure = await ConnectionTestbed.failure {
            try await connection.startDisplay(size: .standard)
        }

        #expect(failure?.stateID == TransportFailure.noSink.stateID)
    }

    @Test func aCredentialIsResolvedOnceForBothTransports() async throws {
        let counter = ResolutionCounter()
        let credentials = ConnectionCredentials {
            counter.record()
            return .password("secret")
        }

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<8 {
                group.addTask { _ = try? await credentials.credential() }
            }
        }

        #expect(counter.value == 1)
        #expect(await credentials.resolutions == 1)
        #expect(await credentials.issued == 8)
    }

    @Test func aFailedResolutionIsNotCached() async throws {
        let counter = ResolutionCounter()
        let credentials = ConnectionCredentials {
            let attempt = counter.record()
            guard attempt > 1 else { throw AuthFailure.noAnswerer }
            return .password("secret")
        }

        let first = await ConnectionTestbed.failure { _ = try await credentials.credential() }
        let second = try await credentials.credential()

        #expect(first != nil)
        #expect(second.method == .password)
        #expect(counter.value == 2)
        #expect(await credentials.resolutions == 2)
    }

    @Test(arguments: [
        (AuthCredential.privateKey(AuthPrivateKey(privateKey: Data())), false, false),
        (AuthCredential.password("secret"), false, false),
        (AuthCredential.keyboardInteractive, true, false),
        (AuthCredential.keyboardInteractive, false, true),
    ])
    func onlyAnUnavoidableSecondPromptIsAnnounced(
        credential: AuthCredential,
        isFirstTransport: Bool,
        expectsNote: Bool
    ) {
        let note = ConnectionPrompting.note(
            for: credential,
            dialling: .control,
            isFirstTransport: isFirstTransport
        )

        #expect((note != nil) == expectsNote)
        #expect(note?.stateID == (expectsNote ? "transport.secondPromptRequired" : nil))
        #expect(note?.detail == (expectsNote ? "control" : nil))
    }
}

final class ResolutionCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int { lock.withLock { count } }

    @discardableResult
    func record() -> Int {
        lock.withLock {
            count += 1
            return count
        }
    }
}
