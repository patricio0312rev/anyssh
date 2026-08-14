import Foundation

public struct BatchResponseParser: Sendable {
    private let nonce: BatchNonce
    private let batch: RemoteBatch
    private let limits: BatchLimits

    public init(nonce: BatchNonce, batch: RemoteBatch, limits: BatchLimits = .default) {
        self.nonce = nonce
        self.batch = batch
        self.limits = limits
    }

    public func parse(_ response: Data) throws -> BatchResponse {
        var framing = reader()
        try framing.append(response)
        return try framing.finish()
    }

    public func reader() -> BatchResponseReader {
        BatchResponseReader(nonce: nonce, batch: batch, limits: limits)
    }
}
