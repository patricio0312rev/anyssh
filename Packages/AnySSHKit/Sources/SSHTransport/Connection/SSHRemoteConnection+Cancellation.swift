import AnySSHCore
import Foundation

struct ControlWork: Sendable {
    let cancel: @Sendable () -> Void
    let drain: @Sendable () async -> Void
}

extension SSHRemoteConnection {
    func register<Value: Sendable>(
        _ operation: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        if controlCancellationDepth > 0 {
            throw TransportFailure.cancelledBySwitch
        }
        let id = nextWorkID
        nextWorkID += 1
        let task = Task { try await operation() }
        work[id] = ControlWork(cancel: { task.cancel() }, drain: { _ = await task.result })
        defer { work[id] = nil }

        do {
            return try await withTaskCancellationHandler {
                try await task.value
            } onCancel: {
                task.cancel()
            }
        } catch {
            await noteControlFailure(error)
            throw error
        }
    }

    public func cancelAll(reason: DisconnectReason = .cancelledBySwitch) async {
        cancellations += 1
        lastCancellationReason = reason
        controlCancellationDepth += 1
        await gate.beginCancellation()
        let pending = Array(work.values)
        work.removeAll()
        for item in pending { item.cancel() }
        for item in pending { await item.drain() }
        await gate.endCancellation()
        controlCancellationDepth = max(0, controlCancellationDepth - 1)
        lastControlActivity = .now
    }

    public var inFlightControlCount: Int {
        work.count
    }
}
