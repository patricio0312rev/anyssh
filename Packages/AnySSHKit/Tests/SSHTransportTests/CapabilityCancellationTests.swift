import AnySSHCore
import Testing

@testable import SSHTransport

@Suite struct CapabilityCancellationTests {
    @Test func sessionSwitchClosesProbeAndDoesNotWriteTheCache() async throws {
        let runner = BlockingCapabilityRunner()
        let probe = SSHCapabilityProbe(runner: runner)
        let cache = CapabilityCache()
        let scope = ActivityScope()
        let remote = RemoteID(rawValue: "cancelled")
        let task = Task {
            try await cache.capabilities(for: remote, using: probe, run: scope.run)
        }

        #expect(await waitForCapabilityCondition { runner.hasStarted })
        await scope.cancelAll()
        _ = await task.result

        #expect(await waitForCapabilityCondition { runner.openChannelCount == 0 })
        #expect(await cache.contains(remote) == false)
    }
}

private actor ActivityScope {
    private var cancel: (@Sendable () -> Void)?

    func run<Value: Sendable>(
        _ operation: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        let task = Task { try await operation() }
        cancel = { task.cancel() }
        defer { cancel = nil }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    func cancelAll() {
        cancel?()
        cancel = nil
    }
}
