import AnySSHCore
import Foundation

public struct MockControlScript: Sendable {
    public var duration: Duration
    public var cancelLatency: Duration
    public var sections: [String: Data]
    public var failures: [String: ErrorState]
    public var exitCodes: [String: Int32]

    public init(
        duration: Duration = .milliseconds(20),
        cancelLatency: Duration = .milliseconds(10),
        sections: [String: Data] = [:],
        failures: [String: ErrorState] = [:],
        exitCodes: [String: Int32] = [:]
    ) {
        self.duration = duration
        self.cancelLatency = cancelLatency
        self.sections = sections
        self.failures = failures
        self.exitCodes = exitCodes
    }

    public static let neverFinishing = MockControlScript(duration: .seconds(3600))

    public func response(to batch: RemoteBatch) throws -> BatchResponse {
        for command in batch.commands {
            if let failure = failures[command.label] { throw failure }
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
