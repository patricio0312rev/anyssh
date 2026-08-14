import AnySSHCore
import Foundation
import Synchronization

public actor ControlChannelGate {
    public static let capacity = 4
    public static let defaultQueueTimeout = Duration.seconds(30)

    private struct Waiter {
        let continuation: CheckedContinuation<Int, any Error>
        let timeoutTask: Task<Void, Never>
    }

    private var nextID = 0
    private var held = Set<Int>()
    private var peak = 0
    private var waiters = [UUID: Waiter]()
    private var order = [UUID]()
    private var cancellationDepth = 0
    private let cancelled = Mutex(Set<UUID>())

    public init() {}

    public var openCount: Int { held.count }
    public var peakOpenCount: Int { peak }
    public var waiterCount: Int { order.count }
    private var isCancelling: Bool { cancellationDepth > 0 }

    public func acquire(
        timeout: Duration = ControlChannelGate.defaultQueueTimeout
    ) async throws -> Int {
        do {
            try Task.checkCancellation()
            if isCancelling { throw TransportFailure.cancelledBySwitch }
            if held.count < Self.capacity {
                return take()
            }
            return try await enqueue(timeout: timeout)
        } catch is CancellationError {
            throw TransportFailure.cancelledBySwitch
        }
    }

    public func release(_ channel: Int) {
        guard held.remove(channel) != nil else { return }
        promote()
    }

    public func beginCancellation(reason: TransportFailure = .cancelledBySwitch) {
        cancellationDepth += 1
        failAllWaiters(reason: reason)
    }

    public func endCancellation() {
        cancellationDepth = max(0, cancellationDepth - 1)
    }

    public func cancelWaiting(reason: TransportFailure = .cancelledBySwitch) {
        failAllWaiters(reason: reason)
    }

    private func failAllWaiters(reason: TransportFailure) {
        for token in order {
            Self.markCancelled(token, in: cancelled)
            guard let waiter = waiters.removeValue(forKey: token) else { continue }
            waiter.timeoutTask.cancel()
            waiter.continuation.resume(throwing: reason)
        }
        order.removeAll()
    }

    private func enqueue(timeout: Duration) async throws -> Int {
        let token = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Int, any Error>) in
                if isCancelling {
                    continuation.resume(throwing: TransportFailure.cancelledBySwitch)
                    return
                }
                let timeoutTask = Task {
                    try? await Task.sleep(for: timeout)
                    guard !Task.isCancelled else { return }
                    await self.fail(token, with: TransportFailure.channelQueueTimeout)
                }
                waiters[token] = Waiter(continuation: continuation, timeoutTask: timeoutTask)
                order.append(token)
                if Task.isCancelled || isCancelled(token) || isCancelling {
                    fail(token, with: TransportFailure.cancelledBySwitch)
                }
            }
        } onCancel: {
            Self.markCancelled(token, in: cancelled)
            Task { await self.fail(token, with: TransportFailure.cancelledBySwitch) }
        }
    }

    private func take() -> Int {
        nextID += 1
        held.insert(nextID)
        peak = max(peak, held.count)
        return nextID
    }

    private func promote() {
        while held.count < Self.capacity, let token = order.first {
            order.removeFirst()
            if isCancelled(token) || isCancelling {
                if let waiter = waiters.removeValue(forKey: token) {
                    waiter.timeoutTask.cancel()
                    waiter.continuation.resume(throwing: TransportFailure.cancelledBySwitch)
                }
                continue
            }
            guard let waiter = waiters.removeValue(forKey: token) else { continue }
            waiter.timeoutTask.cancel()
            waiter.continuation.resume(returning: take())
            return
        }
    }

    private func fail(_ token: UUID, with error: TransportFailure) {
        Self.markCancelled(token, in: cancelled)
        guard let waiter = waiters.removeValue(forKey: token) else { return }
        order.removeAll { $0 == token }
        waiter.timeoutTask.cancel()
        waiter.continuation.resume(throwing: error)
    }

    private func isCancelled(_ token: UUID) -> Bool {
        cancelled.withLock { $0.contains(token) }
    }

    private nonisolated static func markCancelled(
        _ token: UUID,
        in store: borrowing Mutex<Set<UUID>>
    ) {
        store.withLock { _ = $0.insert(token) }
    }
}
