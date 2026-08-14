import Foundation
import Network
import Testing

@testable import AnySSHCore

@Suite struct ReachabilityProbeTests {
    @Test func reachableAgainstALocalListener() async throws {
        let listener = try await LocalTCPListener.open()
        defer { listener.close() }

        let probe = NWConnectionProbe(timeout: .milliseconds(500))
        let result = await probe.probe(remote(host: "127.0.0.1", port: Int(listener.port)))
        #expect(result == .reachable)
    }

    @Test func unreachableAgainstAClosedPort() async throws {
        let listener = try await LocalTCPListener.open()
        let port = listener.port
        listener.close()
        try await Task.sleep(for: .milliseconds(50))

        let probe = NWConnectionProbe(timeout: .milliseconds(500))
        let result = await probe.probe(remote(host: "127.0.0.1", port: Int(port)))
        #expect(result == .unreachable)
    }

    @Test func unknownAgainstASilentAddressWithinBudget() async {
        let probe = NWConnectionProbe(timeout: .milliseconds(200))
        let started = ContinuousClock.now
        let result = await probe.probe(remote(host: "192.0.2.1", port: 65_433))
        let elapsed = ContinuousClock.now - started

        guard result == .unknown else {
            Issue.record("stood down: this network answers for TEST-NET-1", severity: .warning)
            return
        }
        #expect(elapsed < .seconds(3))
    }

    private func remote(host: String, port: Int) -> Remote {
        Remote(
            id: RemoteID(rawValue: "probe-\(host)-\(port)"),
            name: "Probe",
            host: host,
            port: port,
            username: "probe"
        )
    }
}

private final class LocalTCPListener: @unchecked Sendable {
    private let listener: NWListener
    let port: UInt16

    static func open() async throws -> LocalTCPListener {
        let listener = try NWListener(using: .tcp, on: .any)
        let port = try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<UInt16, Error>) in
            let gate = ListenerGate(continuation)
            listener.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if let value = listener.port?.rawValue {
                        gate.resume(returning: value)
                    } else {
                        gate.resume(throwing: ListenerError.missingPort)
                    }
                case .failed(let error):
                    gate.resume(throwing: error)
                default:
                    break
                }
            }
            listener.newConnectionHandler = { connection in
                connection.cancel()
            }
            listener.start(queue: DispatchQueue(label: "anyssh.reachability.listener"))
        }
        return LocalTCPListener(listener: listener, port: port)
    }

    private init(listener: NWListener, port: UInt16) {
        self.listener = listener
        self.port = port
    }

    func close() {
        listener.cancel()
    }
}

private enum ListenerError: Error {
    case missingPort
}

private final class ListenerGate: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<UInt16, Error>?

    init(_ continuation: CheckedContinuation<UInt16, Error>) {
        self.continuation = continuation
    }

    func resume(returning port: UInt16) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(returning: port)
    }

    func resume(throwing error: Error) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(throwing: error)
    }
}
