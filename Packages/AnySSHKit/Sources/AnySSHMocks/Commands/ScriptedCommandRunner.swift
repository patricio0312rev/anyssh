import AnySSHCore
import Foundation

public enum ScriptedCommandMatch: Hashable, Sendable {
    case label(String)
    case arguments([String])
}

public struct ScriptedCommandSpec: Sendable {
    public var match: ScriptedCommandMatch
    public var bytes: Data
    public var exitCode: Int32
    public var delay: Duration
    public var failure: ErrorState?
    public var truncated: Bool

    public init(
        match: ScriptedCommandMatch,
        bytes: Data = Data(),
        exitCode: Int32 = 0,
        delay: Duration = .zero,
        failure: ErrorState? = nil,
        truncated: Bool = false
    ) {
        self.match = match
        self.bytes = bytes
        self.exitCode = exitCode
        self.delay = delay
        self.failure = failure
        self.truncated = truncated
    }

    public static func label(
        _ label: String,
        bytes: Data = Data(),
        exitCode: Int32 = 0,
        delay: Duration = .zero,
        failure: ErrorState? = nil,
        truncated: Bool = false
    ) -> Self {
        Self(
            match: .label(label),
            bytes: bytes,
            exitCode: exitCode,
            delay: delay,
            failure: failure,
            truncated: truncated
        )
    }

    public static func arguments(
        _ arguments: [String],
        bytes: Data = Data(),
        exitCode: Int32 = 0,
        delay: Duration = .zero,
        failure: ErrorState? = nil,
        truncated: Bool = false
    ) -> Self {
        Self(
            match: .arguments(arguments),
            bytes: bytes,
            exitCode: exitCode,
            delay: delay,
            failure: failure,
            truncated: truncated
        )
    }

    func matches(_ command: RemoteCommand) -> Bool {
        switch match {
        case .label(let label): label == command.label
        case .arguments(let arguments): arguments == command.arguments
        }
    }
}

public actor ScriptedCommandRunner: RemoteCommandRunner {
    private var specs: [ScriptedCommandSpec]
    public private(set) var runs = [RemoteBatch]()
    public private(set) var openChannelCount = 0
    public private(set) var peakChannelCount = 0

    public init(specs: [ScriptedCommandSpec] = []) {
        self.specs = specs
    }

    public func setSpecs(_ specs: [ScriptedCommandSpec]) {
        self.specs = specs
    }

    public func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        runs.append(batch)
        openChannel()
        defer { closeChannel() }
        do {
            var sections = [CommandSection]()
            for command in batch.commands {
                let spec = try resolve(command)
                if let failure = spec.failure { throw failure }
                if spec.delay > .zero {
                    try await Task.sleep(for: spec.delay)
                }
                try Task.checkCancellation()
                sections.append(
                    CommandSection(
                        label: command.label,
                        bytes: spec.bytes,
                        exitCode: spec.exitCode,
                        truncated: spec.truncated
                    )
                )
            }
            return BatchResponse(sections: sections)
        } catch is CancellationError {
            throw ErrorState.transport(.cancelledBySwitch)
        }
    }

    private func resolve(_ command: RemoteCommand) throws -> ScriptedCommandSpec {
        if let match = specs.first(where: { $0.matches(command) }) {
            return match
        }
        throw ErrorState.command(.programMissing)
    }

    private func openChannel() {
        openChannelCount += 1
        peakChannelCount = max(peakChannelCount, openChannelCount)
    }

    private func closeChannel() {
        openChannelCount = max(0, openChannelCount - 1)
    }
}
