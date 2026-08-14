import TerminalEmulator

public enum HardwareKeyCode: UInt16, Hashable, Sendable {
    case a = 4
    case b = 5
    case c = 6
    case d = 7
    case e = 8
    case f = 9
    case g = 10
    case h = 11
    case i = 12
    case j = 13
    case k = 14
    case l = 15
    case m = 16
    case n = 17
    case o = 18
    case p = 19
    case q = 20
    case r = 21
    case s = 22
    case t = 23
    case u = 24
    case v = 25
    case w = 26
    case x = 27
    case y = 28
    case z = 29
    case one = 30
    case two = 31
    case three = 32
    case four = 33
    case five = 34
    case six = 35
    case seven = 36
    case eight = 37
    case nine = 38
    case zero = 39
    case enter = 40
    case escape = 41
    case backspace = 42
    case tab = 43
    case space = 44
    case minus = 45
    case equal = 46
    case leftBracket = 47
    case rightBracket = 48
    case backslash = 49
    case semicolon = 51
    case quote = 52
    case grave = 53
    case comma = 54
    case period = 55
    case slash = 56
    case f1 = 58
    case f2 = 59
    case f3 = 60
    case f4 = 61
    case f5 = 62
    case f6 = 63
    case f7 = 64
    case f8 = 65
    case f9 = 66
    case f10 = 67
    case f11 = 68
    case f12 = 69
    case insert = 73
    case home = 74
    case pageUp = 75
    case delete = 76
    case end = 77
    case pageDown = 78
    case right = 79
    case left = 80
    case down = 81
    case up = 82
    case leftControl = 224
    case leftShift = 225
    case leftAlt = 226
    case leftCommand = 227
    case rightControl = 228
    case rightShift = 229
    case rightAlt = 230
    case rightCommand = 231

    public var isModifierOnly: Bool {
        switch self {
        case .leftControl, .leftShift, .leftAlt, .leftCommand,
            .rightControl, .rightShift, .rightAlt, .rightCommand:
            true
        default:
            false
        }
    }

    public var terminalKey: TerminalKey? {
        HardwareKeyMapping.terminalKey(for: self, shift: false)
    }

    public func terminalKey(shift: Bool) -> TerminalKey? {
        HardwareKeyMapping.terminalKey(for: self, shift: shift)
    }
}
