import Foundation
import Network

public final class ReachabilityPathMonitor: @unchecked Sendable {
    public typealias Handler = @Sendable () -> Void

    private let monitor: NWPathMonitor
    private let queue: DispatchQueue

    public init(onChange: @escaping Handler) {
        monitor = NWPathMonitor()
        queue = DispatchQueue(label: "anyssh.reachability.path")
        let gate = PathGate(onChange)
        monitor.pathUpdateHandler = { _ in
            gate.handleUpdate()
        }
    }

    public func start() {
        monitor.start(queue: queue)
    }

    public func cancel() {
        monitor.cancel()
    }
}

private final class PathGate: @unchecked Sendable {
    private let lock = NSLock()
    private var isBaseline = true
    private let onChange: ReachabilityPathMonitor.Handler

    init(_ onChange: @escaping ReachabilityPathMonitor.Handler) {
        self.onChange = onChange
    }

    func handleUpdate() {
        lock.lock()
        if isBaseline {
            isBaseline = false
            lock.unlock()
            return
        }
        lock.unlock()
        onChange()
    }
}
