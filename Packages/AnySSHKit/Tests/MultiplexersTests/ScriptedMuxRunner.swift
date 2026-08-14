import AnySSHCore
import Foundation

final class ScriptedMuxRunner: RemoteCommandRunner, @unchecked Sendable {
    private let lock = NSLock()
    private var recorded = [RemoteBatch]()
    private var openChannels = 0
    private let sections: [String: Data]
    private let exitCodes: [String: Int32]
    private let duration: Duration
    private let cancelLatency: Duration

    init(
        sections: [String: Data],
        exitCodes: [String: Int32] = [:],
        duration: Duration = .milliseconds(5),
        cancelLatency: Duration = .milliseconds(5)
    ) {
        self.sections = sections
        self.exitCodes = exitCodes
        self.duration = duration
        self.cancelLatency = cancelLatency
    }

    var batches: [RemoteBatch] {
        lock.withLock { recorded }
    }

    var openChannelCount: Int {
        lock.withLock { openChannels }
    }

    func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        lock.withLock {
            recorded.append(batch)
            openChannels += 1
        }
        defer {
            lock.withLock { openChannels = max(0, openChannels - 1) }
        }
        do {
            try await Task.sleep(for: duration)
        } catch {
            await Task { [cancelLatency] in
                try? await Task.sleep(for: cancelLatency)
            }.value
            throw ErrorState.transport(.cancelledBySwitch)
        }
        return BatchResponse(
            sections: batch.commands.map { command in
                CommandSection(
                    label: command.label,
                    bytes: sections[command.label] ?? Data(),
                    exitCode: exitCodes[command.label] ?? 0,
                    truncated: false
                )
            }
        )
    }
}
