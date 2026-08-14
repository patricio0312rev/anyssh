import Foundation
import Network

public struct NWConnectionProbe: ReachabilityProbe {
    public var timeout: Duration

    public init(timeout: Duration = .seconds(2)) {
        self.timeout = timeout
    }

    public func probe(_ remote: Remote) async -> Reachability {
        guard let port = NWEndpoint.Port(rawValue: UInt16(clamping: remote.port)) else {
            return .unreachable
        }
        return await connect(
            host: NWEndpoint.Host(remote.host),
            port: port,
            timeout: timeout
        )
    }

    static func isFinal(_ error: NWError) -> Bool {
        guard case .posix(let code) = error else { return false }
        return code == .ECONNREFUSED || code == .ECONNRESET
    }
}

extension NWConnectionProbe {
    fileprivate func connect(
        host: NWEndpoint.Host,
        port: NWEndpoint.Port,
        timeout: Duration
    ) async -> Reachability {
        let parameters = NWConnectionParameters.tcp()
        let connection = NWConnection(host: host, port: port, using: parameters)
        let queue = DispatchQueue(label: "anyssh.reachability.probe")
        let gate = ProbeGate()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Reachability, Never>) in
                gate.arm(continuation)
                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        gate.resume(.reachable)
                        connection.cancel()
                    case .failed:
                        gate.resume(.unreachable)
                        connection.cancel()
                    case .cancelled:
                        gate.resume(.unknown)
                    case .waiting(let error):
                        if Self.isFinal(error) {
                            gate.resume(.unreachable)
                            connection.cancel()
                        }
                    default:
                        break
                    }
                }
                connection.start(queue: queue)
                queue.asyncAfter(deadline: .now() + timeout.seconds) {
                    gate.resume(.unknown)
                    connection.cancel()
                }
            }
        } onCancel: {
            gate.resume(.unknown)
            connection.cancel()
        }
    }
}

private final class ProbeGate: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Reachability, Never>?
    private var finished = false
    private var pending: Reachability?

    func arm(_ continuation: CheckedContinuation<Reachability, Never>) {
        lock.lock()
        if let pending {
            self.pending = nil
            finished = true
            lock.unlock()
            continuation.resume(returning: pending)
            return
        }
        self.continuation = continuation
        lock.unlock()
    }

    func resume(_ value: Reachability) {
        lock.lock()
        if finished {
            lock.unlock()
            return
        }
        if let continuation {
            finished = true
            self.continuation = nil
            lock.unlock()
            continuation.resume(returning: value)
            return
        }
        pending = value
        lock.unlock()
    }
}

extension Duration {
    fileprivate var seconds: TimeInterval {
        let components = self.components
        return TimeInterval(components.seconds)
            + TimeInterval(components.attoseconds) / 1_000_000_000_000_000_000
    }

}
