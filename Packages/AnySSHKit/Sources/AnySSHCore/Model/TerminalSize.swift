public struct TerminalSize: Hashable, Sendable {
    public static let standard = TerminalSize(columns: 80, rows: 24)

    public let columns: Int
    public let rows: Int
    public let pixelWidth: Int
    public let pixelHeight: Int

    public init(columns: Int, rows: Int, pixelWidth: Int = 0, pixelHeight: Int = 0) {
        self.columns = max(1, columns)
        self.rows = max(1, rows)
        self.pixelWidth = max(0, pixelWidth)
        self.pixelHeight = max(0, pixelHeight)
    }

    public var cellCount: Int {
        columns * rows
    }
}
