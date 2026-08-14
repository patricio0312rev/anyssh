public struct PumpConfiguration: Hashable, Sendable {
    public static let `default` = PumpConfiguration()

    public let sliceLimit: Int

    public let highWaterMark: Int

    public let quiescenceYields: Int

    public init(
        sliceLimit: Int = 64 * 1024,
        highWaterMark: Int = 256 * 1024,
        quiescenceYields: Int = 2
    ) {
        let slice = max(1, sliceLimit)
        self.sliceLimit = slice
        self.highWaterMark = max(slice, highWaterMark)
        self.quiescenceYields = max(0, quiescenceYields)
    }
}

public struct PumpMetrics: Hashable, Sendable {
    public internal(set) var deliveredSlices = 0
    public internal(set) var deliveredBytes = 0
    public internal(set) var suspensions = 0
    public internal(set) var peakPendingBytes = 0
    public internal(set) var metadataDeliveries = 0

    public init() {}
}
