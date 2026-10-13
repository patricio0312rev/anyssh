public struct ImagePasteLimits: Sendable, Hashable {
    public static let standard = ImagePasteLimits(
        maxBytes: 3_750_000,
        maxPixelDimension: 2048,
        jpegQualities: [0.85, 0.7, 0.55, 0.4]
    )

    public let maxBytes: Int
    public let maxPixelDimension: Int
    public let jpegQualities: [Double]

    public init(maxBytes: Int, maxPixelDimension: Int, jpegQualities: [Double]) {
        self.maxBytes = maxBytes
        self.maxPixelDimension = maxPixelDimension
        self.jpegQualities = jpegQualities
    }

    public func fits(byteCount: Int, width: Int, height: Int) -> Bool {
        byteCount <= maxBytes && max(width, height) <= maxPixelDimension
    }
}
