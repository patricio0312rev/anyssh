import AnySSHCore
import Foundation
import Synchronization

@testable import SSHTransport

final class CapabilityRecordingRunner: RemoteCommandRunner, @unchecked Sendable {
    private let response: BatchResponse
    private let lock = NSLock()
    private var recordedBatches = [RemoteBatch]()

    init(bytes: Data, exitCode: Int32 = 0) {
        response = BatchResponse(sections: [
            CommandSection(
                label: CapabilityProbeCommand.label,
                bytes: bytes,
                exitCode: exitCode,
                truncated: false
            )
        ])
    }

    var batches: [RemoteBatch] {
        lock.withLock { recordedBatches }
    }

    func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        lock.withLock { recordedBatches.append(batch) }
        return response
    }
}

final class CountingCapabilityProbe: CapabilityProbe, @unchecked Sendable {
    let value: HostCapabilities
    private let lock = NSLock()
    private var count = 0

    init(value: HostCapabilities) {
        self.value = value
    }

    var calls: Int { lock.withLock { count } }

    func probe() async throws -> HostCapabilities {
        lock.withLock { count += 1 }
        return value
    }
}

final class BlockingCapabilityRunner: RemoteCommandRunner, @unchecked Sendable {
    private let lock = NSLock()
    private var started = false
    private var open = 0

    var hasStarted: Bool { lock.withLock { started } }
    var openChannelCount: Int { lock.withLock { open } }

    func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        lock.withLock {
            started = true
            open += 1
        }
        defer { lock.withLock { open -= 1 } }
        try await Task.sleep(for: .seconds(3600))
        return BatchResponse(sections: [])
    }
}

func waitForCapabilityCondition(
    _ condition: @escaping @Sendable () -> Bool,
    turns: Int = 10_000
) async -> Bool {
    for _ in 0..<turns {
        if condition() { return true }
        await Task.yield()
    }
    return condition()
}
