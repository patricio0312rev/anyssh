import Foundation

@testable import SSHTransport

enum LiveSetupRetry {
    static let attempts = 3
    static let pause = Duration.milliseconds(150)

    static func run<Value>(
        _ attempt: () async throws -> Value
    ) async throws -> Value {
        var lastFailure: (any Error)?
        for index in 0..<attempts {
            do {
                return try await attempt()
            } catch {
                lastFailure = error
                guard index + 1 < attempts, isTransient(error) else { break }
                try? await Task.sleep(for: pause)
            }
        }
        throw lastFailure ?? TransportFailure.notConnected
    }

    static func controlRun<Value>(
        channelCounters: () -> (open: Int, closed: Int),
        _ attempt: () async throws -> Value
    ) async throws -> Value {
        var lastFailure: (any Error)?
        for index in 0..<attempts {
            let before = channelCounters()
            do {
                return try await attempt()
            } catch {
                lastFailure = error
                let after = channelCounters()
                let openedNothing = after.open == 0 && after.closed == before.closed
                guard index + 1 < attempts, isTransient(error), openedNothing else { break }
                try? await Task.sleep(for: pause)
            }
        }
        throw lastFailure ?? TransportFailure.notConnected
    }

    private static func isTransient(_ error: any Error) -> Bool {
        guard let failure = error as? TransportFailure else { return false }
        return transientStateIDs.contains(failure.stateID)
    }

    private static let transientStateIDs: Set<String> = [
        "transport.dialFailed",
        "transport.handshakeFailed",
        "transport.notConnected",
        "transport.keepaliveTimeout",
        "transport.connectionLost",
    ]
}
