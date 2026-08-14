import AnySSHCore

public struct TransferProgress: Hashable, Sendable {
    public let transferredBytes: Int
    public let totalBytes: Int

    public init(transferredBytes: Int, totalBytes: Int) {
        self.transferredBytes = max(0, transferredBytes)
        self.totalBytes = max(0, totalBytes)
    }

    public var fraction: Double {
        totalBytes == 0 ? 0 : Double(transferredBytes) / Double(totalBytes)
    }

    public var isComplete: Bool {
        totalBytes > 0 && transferredBytes >= totalBytes
    }
}
