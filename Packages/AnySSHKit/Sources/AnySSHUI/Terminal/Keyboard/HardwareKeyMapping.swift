import TerminalEmulator

enum HardwareKeyMapping {
    static func terminalKey(for code: HardwareKeyCode, shift: Bool = false) -> TerminalKey? {
        if let functional = functionalKey(for: code) { return functional }
        guard let character = character(for: code, shift: shift) else { return nil }
        return .character(character)
    }

    private static func functionalKey(for code: HardwareKeyCode) -> TerminalKey? {
        switch code {
        case .enter: .enter
        case .escape: .escape
        case .backspace: .backspace
        case .tab: .tab
        case .f1: .function(1)
        case .f2: .function(2)
        case .f3: .function(3)
        case .f4: .function(4)
        case .f5: .function(5)
        case .f6: .function(6)
        case .f7: .function(7)
        case .f8: .function(8)
        case .f9: .function(9)
        case .f10: .function(10)
        case .f11: .function(11)
        case .f12: .function(12)
        case .insert: .insert
        case .home: .home
        case .pageUp: .pageUp
        case .delete: .delete
        case .end: .end
        case .pageDown: .pageDown
        case .right: .right
        case .left: .left
        case .down: .down
        case .up: .up
        default: nil
        }
    }

    private static func character(for code: HardwareKeyCode, shift: Bool) -> Character? {
        switch code {
        case .a: shift ? "A" : "a"
        case .b: shift ? "B" : "b"
        case .c: shift ? "C" : "c"
        case .d: shift ? "D" : "d"
        case .e: shift ? "E" : "e"
        case .f: shift ? "F" : "f"
        case .g: shift ? "G" : "g"
        case .h: shift ? "H" : "h"
        case .i: shift ? "I" : "i"
        case .j: shift ? "J" : "j"
        case .k: shift ? "K" : "k"
        case .l: shift ? "L" : "l"
        case .m: shift ? "M" : "m"
        case .n: shift ? "N" : "n"
        case .o: shift ? "O" : "o"
        case .p: shift ? "P" : "p"
        case .q: shift ? "Q" : "q"
        case .r: shift ? "R" : "r"
        case .s: shift ? "S" : "s"
        case .t: shift ? "T" : "t"
        case .u: shift ? "U" : "u"
        case .v: shift ? "V" : "v"
        case .w: shift ? "W" : "w"
        case .x: shift ? "X" : "x"
        case .y: shift ? "Y" : "y"
        case .z: shift ? "Z" : "z"
        case .one: shift ? "!" : "1"
        case .two: shift ? "@" : "2"
        case .three: shift ? "#" : "3"
        case .four: shift ? "$" : "4"
        case .five: shift ? "%" : "5"
        case .six: shift ? "^" : "6"
        case .seven: shift ? "&" : "7"
        case .eight: shift ? "*" : "8"
        case .nine: shift ? "(" : "9"
        case .zero: shift ? ")" : "0"
        case .space: " "
        case .minus: shift ? "_" : "-"
        case .equal: shift ? "+" : "="
        case .leftBracket: shift ? "{" : "["
        case .rightBracket: shift ? "}" : "]"
        case .backslash: shift ? "|" : "\\"
        case .semicolon: shift ? ":" : ";"
        case .quote: shift ? "\"" : "'"
        case .grave: shift ? "~" : "`"
        case .comma: shift ? "<" : ","
        case .period: shift ? ">" : "."
        case .slash: shift ? "?" : "/"
        case .leftControl, .leftShift, .leftAlt, .leftCommand,
            .rightControl, .rightShift, .rightAlt, .rightCommand,
            .enter, .escape, .backspace, .tab,
            .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8, .f9, .f10, .f11, .f12,
            .insert, .home, .pageUp, .delete, .end, .pageDown,
            .right, .left, .down, .up:
            nil
        }
    }
}
