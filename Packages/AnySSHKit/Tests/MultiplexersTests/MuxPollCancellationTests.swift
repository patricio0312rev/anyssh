import AnySSHCore
import Foundation
import Testing

@testable import Multiplexers

@Suite struct MuxPollCancellationTests {
    @Test func sessionSwitchCancelsPollAndClosesChannel() async throws {
        let runner = ScriptedMuxRunner(
            sections: [
                TmuxCommands.sessionsLabel: try MuxFixtureData.bytes("tmux-list-sessions.txt"),
                TmuxCommands.windowsLabel: try MuxFixtureData.bytes("tmux-list-windows.txt"),
                TmuxCommands.panesLabel: try MuxFixtureData.bytes("tmux-list-panes.txt"),
            ],
            duration: .seconds(30),
            cancelLatency: .milliseconds(20)
        )
        let adapter = TmuxAdapter(runner: runner)
        let poller = MuxTopologyPoller(adapter: adapter)
        let scope = MuxTestActivityScope()

        let task = Task {
            try await poller.pollOnce(session: MuxSessionID(rawValue: "$1")) { operation in
                try await scope.run(operation)
            }
        }

        #expect(await waitUntil { runner.openChannelCount > 0 })
        await scope.cancelAll()
        let result = await task.result
        #expect(result.isFailure)
        #expect(await waitUntil { runner.openChannelCount == 0 })
    }

    @Test func suspendedVisibilityDoesNotPollUntilVisible() async throws {
        #expect(MuxPollCadence.interval(for: .visible) == .seconds(1))
        #expect(MuxPollCadence.interval(for: .background) == .seconds(5))
        #expect(MuxPollCadence.interval(for: .suspended) == nil)

        let runner = ScriptedMuxRunner(sections: [
            TmuxCommands.sessionsLabel: try MuxFixtureData.bytes("tmux-list-sessions.txt"),
            TmuxCommands.windowsLabel: try MuxFixtureData.bytes("tmux-list-windows.txt"),
            TmuxCommands.panesLabel: try MuxFixtureData.bytes("tmux-list-panes.txt"),
        ])
        let adapter = TmuxAdapter(runner: runner)
        let poller = MuxTopologyPoller(adapter: adapter)
        await poller.setVisibility(.suspended)
        let scope = MuxTestActivityScope()

        let task = Task {
            try await poller.pollOnce(session: MuxSessionID(rawValue: "$1")) { operation in
                try await scope.run(operation)
            }
        }
        try await Task.sleep(for: .milliseconds(50))
        #expect(runner.batches.isEmpty)
        await poller.setVisibility(.visible)
        let snapshot = try await task.value
        #expect(snapshot.session.name == "main")
        #expect(!runner.batches.isEmpty)
    }
}

actor MuxTestActivityScope {
    private var cancellations = [UUID: @Sendable () -> Void]()

    func run<Value: Sendable>(
        _ operation: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        let id = UUID()
        let task = Task { try await operation() }
        cancellations[id] = { task.cancel() }
        defer { cancellations.removeValue(forKey: id) }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    func cancelAll() {
        let operations = cancellations.values
        cancellations.removeAll()
        operations.forEach { $0() }
    }
}

private func waitUntil(
    timeout: Duration = .seconds(2),
    _ condition: @escaping @Sendable () -> Bool
) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while ContinuousClock.now < deadline {
        if condition() { return true }
        try? await Task.sleep(for: .milliseconds(10))
    }
    return condition()
}

extension Result {
    fileprivate var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
}
