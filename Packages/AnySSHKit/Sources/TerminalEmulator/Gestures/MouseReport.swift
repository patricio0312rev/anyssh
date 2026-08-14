public enum TerminalMouseButton: UInt8, Sendable {
    case primary = 0
    case wheelUp = 64
    case wheelDown = 65
}

public struct TerminalMouseReport: Hashable, Sendable {
    public let button: TerminalMouseButton
    public let column: Int
    public let row: Int
    public let pressed: Bool

    public init(button: TerminalMouseButton, column: Int, row: Int, pressed: Bool) {
        self.button = button
        self.column = column
        self.row = row
        self.pressed = pressed
    }

    public var isWheel: Bool {
        button == .wheelUp || button == .wheelDown
    }

    public var sgrBytes: [UInt8] {
        if isWheel {
            return Array("\u{1B}[<\(button.rawValue);\(column + 1);\(row + 1)M".utf8)
        }
        let action = pressed ? UInt8(button.rawValue) : 3
        let suffix = pressed ? "M" : "m"
        return Array("\u{1B}[<\(action);\(column + 1);\(row + 1)\(suffix)".utf8)
    }
}
