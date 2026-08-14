public struct ScreenSize: Hashable, Sendable {
    public static let standard = ScreenSize(columns: 80, rows: 24)

    public let columns: Int
    public let rows: Int

    public init(columns: Int, rows: Int) {
        self.columns = max(1, columns)
        self.rows = max(1, rows)
    }

    public var cellCount: Int {
        columns * rows
    }
}
