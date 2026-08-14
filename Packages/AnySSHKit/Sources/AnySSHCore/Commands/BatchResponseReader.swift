import Foundation

public struct BatchResponseReader: Sendable {
    private static let sigpipeExit: Int32 = 141

    private let batch: RemoteBatch
    private var stream: BatchResponseStream

    public init(nonce: BatchNonce, batch: RemoteBatch, limits: BatchLimits = .default) {
        self.batch = batch
        self.stream = BatchResponseStream(
            nonce: nonce,
            labels: batch.commands.map(\.label),
            limits: limits
        )
    }

    public mutating func append(_ chunk: Data) throws {
        try stream.append(chunk)
    }

    public func finish() throws -> BatchResponse {
        BatchResponse(sections: try stream.finish().map(section))
    }

    private func section(_ frame: BatchFrame) -> CommandSection {
        let command = batch.commands[frame.index]
        let truncated =
            command.byteCap.map {
                frame.exitCode == Self.sigpipeExit || frame.bytes.count >= $0
            } ?? false
        return CommandSection(
            label: command.label,
            bytes: frame.bytes,
            exitCode: frame.exitCode,
            truncated: truncated
        )
    }
}
