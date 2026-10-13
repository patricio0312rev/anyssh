public struct ClipboardContentKinds: Sendable, Hashable {
    public let hasText: Bool
    public let hasImage: Bool

    public init(hasText: Bool, hasImage: Bool) {
        self.hasText = hasText
        self.hasImage = hasImage
    }
}
