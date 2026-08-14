import AnySSHCore
import Foundation

public actor SessionActivityScope {
    private struct Entry: Sendable {
        let cancel: @Sendable () -> Void
        let drain: @Sendable () async -> Void
        let userInitiated: Bool
    }

    public let sessionID: SessionID
    private let connection: any RemoteConnection
    private var work = [Int: Entry]()
    private var nextWorkID = 0
    private var cancellationDepth = 0
    public private(set) var cancellations = 0

    public init(sessionID: SessionID, connection: any RemoteConnection) {
        self.sessionID = sessionID
        self.connection = connection
    }

    public func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        try await register(batch: batch, userInitiated: false)
    }

    public func runUserInitiated(_ batch: RemoteBatch) async throws -> BatchResponse {
        try await register(batch: batch, userInitiated: true)
    }

    public func run<Value: Sendable>(
        _ operation: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        try await register(operation: operation, userInitiated: false)
    }

    public func runUserInitiated<Value: Sendable>(
        _ operation: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        try await register(operation: operation, userInitiated: true)
    }

    public func cancelAll(reason: DisconnectReason = .cancelledBySwitch) async {
        cancellations += 1
        cancellationDepth += 1
        defer { cancellationDepth = max(0, cancellationDepth - 1) }

        let pending = work.filter { !$0.value.userInitiated }
        work = work.filter { $0.value.userInitiated }
        for entry in pending.values { entry.cancel() }
        for entry in pending.values { await entry.drain() }
    }

    public var inFlightControlCount: Int {
        work.count
    }

    private func register(batch: RemoteBatch, userInitiated: Bool) async throws -> BatchResponse {
        if cancellationDepth > 0 {
            throw ErrorState.transport(.cancelledBySwitch)
        }
        let id = nextWorkID
        nextWorkID += 1
        let connection = connection
        let task = Task { try await connection.run(batch) }
        work[id] = Entry(
            cancel: { task.cancel() },
            drain: { _ = await task.result },
            userInitiated: userInitiated
        )
        defer { work[id] = nil }

        do {
            return try await withTaskCancellationHandler {
                try await task.value
            } onCancel: {
                task.cancel()
            }
        } catch is CancellationError {
            throw ErrorState.transport(.cancelledBySwitch)
        }
    }

    private func register<Value: Sendable>(
        operation: @escaping @Sendable () async throws -> Value,
        userInitiated: Bool
    ) async throws -> Value {
        if cancellationDepth > 0 {
            throw ErrorState.transport(.cancelledBySwitch)
        }
        let id = nextWorkID
        nextWorkID += 1
        let task = Task { try await operation() }
        work[id] = Entry(
            cancel: { task.cancel() },
            drain: { _ = await task.result },
            userInitiated: userInitiated
        )
        defer { work[id] = nil }

        do {
            return try await withTaskCancellationHandler {
                try await task.value
            } onCancel: {
                task.cancel()
            }
        } catch is CancellationError {
            throw ErrorState.transport(.cancelledBySwitch)
        }
    }
}
