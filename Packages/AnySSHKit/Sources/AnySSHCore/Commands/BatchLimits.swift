public struct BatchLimits: Hashable, Sendable {
    public static let `default` = BatchLimits(maximumResponseBytes: 4 << 20)

    public let maximumResponseBytes: Int

    public init(maximumResponseBytes: Int) {
        self.maximumResponseBytes = max(0, maximumResponseBytes)
    }
}
