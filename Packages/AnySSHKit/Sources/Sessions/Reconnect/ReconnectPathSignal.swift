import AnySSHCore
import Foundation

public final class ReconnectPathSignal: ReconnectPathSignaling, @unchecked Sendable {
    private let lock = NSLock()
    private var monitor: ReachabilityPathMonitor?
    private var onChange: (@Sendable () -> Void)?

    public init() {}

    public func start(onChange: @escaping @Sendable () -> Void) {
        lock.lock()
        self.onChange = onChange
        let monitor = ReachabilityPathMonitor { [weak self] in
            self?.onChange?()
        }
        self.monitor = monitor
        lock.unlock()
        monitor.start()
    }

    public func cancel() {
        lock.lock()
        monitor?.cancel()
        monitor = nil
        onChange = nil
        lock.unlock()
    }
}
