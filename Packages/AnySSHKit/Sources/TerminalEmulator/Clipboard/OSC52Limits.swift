public enum OSC52Limits: Sendable {
    public static let maxDecodedBytes = 256 * 1024

    public static let transportChunkBytes = 64 * 1024

    public static let defaultSelection = "c"
}
