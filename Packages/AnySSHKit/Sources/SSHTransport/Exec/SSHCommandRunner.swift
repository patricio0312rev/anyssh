import AnySSHCore
import Foundation

public actor SSHCommandRunner: RemoteCommandRunner {
    private let connection: SSHRemoteConnection
    private let gate: ControlChannelGate
    private let queueTimeout: Duration

    public private(set) var lastBatchChannelID: Int?
    public private(set) var lastRawChannelID: Int?

    public init(
        connection: SSHRemoteConnection,
        queueTimeout: Duration = ControlChannelGate.defaultQueueTimeout
    ) {
        self.connection = connection
        self.gate = connection.gate
        self.queueTimeout = queueTimeout
    }

    public var openChannelCount: Int {
        get async { await gate.openCount }
    }

    public var peakOpenCount: Int {
        get async { await gate.peakOpenCount }
    }

    public var connectionOpenChannelCount: Int {
        connection.ledger.openCount
    }

    public var connectionPeakOpenCount: Int {
        connection.ledger.peakOpenCount
    }

    public func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        let connection = self.connection
        return try await holdingChannel(recordingBatch: true) {
            try await connection.run(batch)
        }
    }

    public func executeRaw(_ command: String) async throws -> Data {
        let wrapped = LoginShellWrapper.wrap(command)
        let connection = self.connection
        return try await holdingChannel(recordingBatch: false) {
            try await connection.execute(wrapped)
        }
    }

    private func holdingChannel<Value: Sendable>(
        recordingBatch: Bool,
        _ operation: @Sendable @escaping () async throws -> Value
    ) async throws -> Value {
        let gate = self.gate
        let queueTimeout = self.queueTimeout
        let connection = self.connection
        do {
            let (channel, value) = try await connection.register {
                let channel = try await gate.acquire(timeout: queueTimeout)
                do {
                    try Task.checkCancellation()
                    let value = try await operation()
                    await gate.release(channel)
                    return (channel, value)
                } catch {
                    await gate.release(channel)
                    throw error
                }
            }
            if recordingBatch {
                lastBatchChannelID = channel
            } else {
                lastRawChannelID = channel
            }
            return value
        } catch {
            throw Self.mapCancellation(error)
        }
    }

    private static func mapCancellation(_ error: any Error) -> any Error {
        if error is CancellationError { return TransportFailure.cancelledBySwitch }
        return error
    }
}
