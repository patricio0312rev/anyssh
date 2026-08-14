@testable import TerminalEmulator

enum InputFunctionalTable {
    static let rows: [KeyEncodingCase] = cursor + modifiedCursor + editing + controlCodes + functionKeys

    private static let cursor: [KeyEncodingCase] = [
        KeyEncodingCase("up", .up, bytes: inputEscape("[A")),
        KeyEncodingCase("down", .down, bytes: inputEscape("[B")),
        KeyEncodingCase("right", .right, bytes: inputEscape("[C")),
        KeyEncodingCase("left", .left, bytes: inputEscape("[D")),
        KeyEncodingCase(
            "up in application cursor mode", .up, mode: InputModes.application, bytes: inputEscape("OA")),
        KeyEncodingCase(
            "down in application cursor mode", .down, mode: InputModes.application, bytes: inputEscape("OB")),
        KeyEncodingCase(
            "right in application cursor mode", .right, mode: InputModes.application, bytes: inputEscape("OC")
        ),
        KeyEncodingCase(
            "left in application cursor mode", .left, mode: InputModes.application, bytes: inputEscape("OD")),
        KeyEncodingCase("home", .home, bytes: inputEscape("[H")),
        KeyEncodingCase("end", .end, bytes: inputEscape("[F")),
        KeyEncodingCase(
            "home in application cursor mode", .home, mode: InputModes.application, bytes: inputEscape("OH")),
        KeyEncodingCase(
            "end in application cursor mode", .end, mode: InputModes.application, bytes: inputEscape("OF")),
    ]

    private static let modifiedCursor: [KeyEncodingCase] = [
        KeyEncodingCase("shift+up", .up, .shift, bytes: inputEscape("[1;2A")),
        KeyEncodingCase("alt+right", .right, .alt, bytes: inputEscape("[1;3C")),
        KeyEncodingCase("alt+shift+left", .left, [.alt, .shift], bytes: inputEscape("[1;4D")),
        KeyEncodingCase("control+up", .up, .control, bytes: inputEscape("[1;5A")),
        KeyEncodingCase("control+left", .left, .control, bytes: inputEscape("[1;5D")),
        KeyEncodingCase("control+right", .right, .control, bytes: inputEscape("[1;5C")),
        KeyEncodingCase("control+shift+down", .down, [.control, .shift], bytes: inputEscape("[1;6B")),
        KeyEncodingCase("control+alt+up", .up, [.control, .alt], bytes: inputEscape("[1;7A")),
        KeyEncodingCase(
            "a modified arrow stays CSI in application cursor mode",
            .up,
            .control,
            mode: InputModes.application,
            bytes: inputEscape("[1;5A")
        ),
        KeyEncodingCase("shift+home", .home, .shift, bytes: inputEscape("[1;2H")),
        KeyEncodingCase("control+end", .end, .control, bytes: inputEscape("[1;5F")),
        KeyEncodingCase(
            "a modified home stays CSI in application cursor mode",
            .home,
            .control,
            mode: InputModes.application,
            bytes: inputEscape("[1;5H")
        ),
    ]

    private static let editing: [KeyEncodingCase] = [
        KeyEncodingCase("page up", .pageUp, bytes: inputEscape("[5~")),
        KeyEncodingCase("page down", .pageDown, bytes: inputEscape("[6~")),
        KeyEncodingCase(
            "page up ignores application cursor mode", .pageUp, mode: InputModes.application,
            bytes: inputEscape("[5~")),
        KeyEncodingCase("control+page up", .pageUp, .control, bytes: inputEscape("[5;5~")),
        KeyEncodingCase("shift+page down", .pageDown, .shift, bytes: inputEscape("[6;2~")),
        KeyEncodingCase("delete", .delete, bytes: inputEscape("[3~")),
        KeyEncodingCase("control+delete", .delete, .control, bytes: inputEscape("[3;5~")),
        KeyEncodingCase("insert", .insert, bytes: inputEscape("[2~")),
        KeyEncodingCase("shift+insert", .insert, .shift, bytes: inputEscape("[2;2~")),
    ]

    private static let controlCodes: [KeyEncodingCase] = [
        KeyEncodingCase("escape", .escape, bytes: [0x1b]),
        KeyEncodingCase("alt+escape", .escape, .alt, bytes: [0x1b, 0x1b]),
        KeyEncodingCase("enter", .enter, bytes: [0x0d]),
        KeyEncodingCase("enter in newline mode", .enter, mode: InputModes.newline, bytes: [0x0d, 0x0a]),
        KeyEncodingCase("alt+enter", .enter, .alt, bytes: [0x1b, 0x0d]),
        KeyEncodingCase("tab", .tab, bytes: [0x09]),
        KeyEncodingCase("shift+tab", .tab, .shift, bytes: inputEscape("[Z")),
        KeyEncodingCase("alt+tab", .tab, .alt, bytes: [0x1b, 0x09]),
        KeyEncodingCase("backspace sends DEL", .backspace, bytes: [0x7f]),
        KeyEncodingCase(
            "backspace sends BS when configured to", .backspace, mode: InputModes.controlH, bytes: [0x08]),
        KeyEncodingCase("control+backspace always sends BS", .backspace, .control, bytes: [0x08]),
        KeyEncodingCase("alt+backspace", .backspace, .alt, bytes: [0x1b, 0x7f]),
    ]

    private static let functionKeys: [KeyEncodingCase] = [
        KeyEncodingCase("f1", .function(1), bytes: inputEscape("OP")),
        KeyEncodingCase("f2", .function(2), bytes: inputEscape("OQ")),
        KeyEncodingCase("f3", .function(3), bytes: inputEscape("OR")),
        KeyEncodingCase("f4", .function(4), bytes: inputEscape("OS")),
        KeyEncodingCase("f5", .function(5), bytes: inputEscape("[15~")),
        KeyEncodingCase("f6", .function(6), bytes: inputEscape("[17~")),
        KeyEncodingCase("f7", .function(7), bytes: inputEscape("[18~")),
        KeyEncodingCase("f8", .function(8), bytes: inputEscape("[19~")),
        KeyEncodingCase("f9", .function(9), bytes: inputEscape("[20~")),
        KeyEncodingCase("f10", .function(10), bytes: inputEscape("[21~")),
        KeyEncodingCase("f11", .function(11), bytes: inputEscape("[23~")),
        KeyEncodingCase("f12", .function(12), bytes: inputEscape("[24~")),
        KeyEncodingCase(
            "f1 ignores application cursor mode", .function(1), mode: InputModes.application,
            bytes: inputEscape("OP")),
        KeyEncodingCase("shift+f1", .function(1), .shift, bytes: inputEscape("[1;2P")),
        KeyEncodingCase("alt+f1", .function(1), .alt, bytes: inputEscape("[1;3P")),
        KeyEncodingCase("control+f1", .function(1), .control, bytes: inputEscape("[1;5P")),
        KeyEncodingCase("control+shift+f4", .function(4), [.control, .shift], bytes: inputEscape("[1;6S")),
        KeyEncodingCase("control+f5", .function(5), .control, bytes: inputEscape("[15;5~")),
        KeyEncodingCase("shift+f12", .function(12), .shift, bytes: inputEscape("[24;2~")),
        KeyEncodingCase("f13 is not a key", .function(13), bytes: []),
    ]
}
