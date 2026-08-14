public enum TerminalKey: Hashable, Sendable {
    case character(Character)
    case enter
    case escape
    case tab
    case backspace
    case delete
    case insert
    case up
    case down
    case left
    case right
    case home
    case end
    case pageUp
    case pageDown
    case function(Int)

    public static let space = TerminalKey.character(" ")
}
