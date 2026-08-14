@testable import TerminalEmulator

enum InputCharacterTable {
    static let rows: [KeyEncodingCase] = controlLetters + controlSymbols + plain + alt

    private static let controlLetters: [KeyEncodingCase] = [
        KeyEncodingCase("control+a", .character("a"), .control, bytes: [0x01]),
        KeyEncodingCase("control+c", .character("c"), .control, bytes: [0x03]),
        KeyEncodingCase("control+d", .character("d"), .control, bytes: [0x04]),
        KeyEncodingCase("control+e", .character("e"), .control, bytes: [0x05]),
        KeyEncodingCase("control+z", .character("z"), .control, bytes: [0x1a]),
        KeyEncodingCase(
            "control+shift+c folds to the same code", .character("c"), [.control, .shift], bytes: [0x03]),
        KeyEncodingCase("control over an already capital C", .character("C"), .control, bytes: [0x03]),
    ]

    private static let controlSymbols: [KeyEncodingCase] = [
        KeyEncodingCase("control+space", .space, .control, bytes: [0x00]),
        KeyEncodingCase("control+@", .character("@"), .control, bytes: [0x00]),
        KeyEncodingCase("control+2", .character("2"), .control, bytes: [0x00]),
        KeyEncodingCase("control+3", .character("3"), .control, bytes: [0x1b]),
        KeyEncodingCase("control+[", .character("["), .control, bytes: [0x1b]),
        KeyEncodingCase("control+4", .character("4"), .control, bytes: [0x1c]),
        KeyEncodingCase("control+backslash", .character("\\"), .control, bytes: [0x1c]),
        KeyEncodingCase("control+5", .character("5"), .control, bytes: [0x1d]),
        KeyEncodingCase("control+]", .character("]"), .control, bytes: [0x1d]),
        KeyEncodingCase("control+6", .character("6"), .control, bytes: [0x1e]),
        KeyEncodingCase("control+^", .character("^"), .control, bytes: [0x1e]),
        KeyEncodingCase("control+7", .character("7"), .control, bytes: [0x1f]),
        KeyEncodingCase("control+underscore", .character("_"), .control, bytes: [0x1f]),
        KeyEncodingCase("control+slash", .character("/"), .control, bytes: [0x1f]),
        KeyEncodingCase("control+8", .character("8"), .control, bytes: [0x7f]),
        KeyEncodingCase("control+?", .character("?"), .control, bytes: [0x7f]),
        KeyEncodingCase("control is inert over 1", .character("1"), .control, bytes: [0x31]),
        KeyEncodingCase(
            "control is inert over a non-ascii key", .character("é"), .control, bytes: [0xc3, 0xa9]),
    ]

    private static let plain: [KeyEncodingCase] = [
        KeyEncodingCase("a", .character("a"), bytes: [0x61]),
        KeyEncodingCase("shift+a", .character("a"), .shift, bytes: [0x41]),
        KeyEncodingCase("an already shifted A", .character("A"), bytes: [0x41]),
        KeyEncodingCase("shift over an already shifted A", .character("A"), .shift, bytes: [0x41]),
        KeyEncodingCase("a multibyte character", .character("é"), bytes: [0xc3, 0xa9]),
        KeyEncodingCase("shift is inert over a digit", .character("1"), .shift, bytes: [0x31]),
        KeyEncodingCase("space", .space, bytes: [0x20]),
    ]

    private static let alt: [KeyEncodingCase] = [
        KeyEncodingCase("alt+f", .character("f"), .alt, bytes: [0x1b, 0x66]),
        KeyEncodingCase("alt+b", .character("b"), .alt, bytes: [0x1b, 0x62]),
        KeyEncodingCase("alt+shift+f", .character("f"), [.alt, .shift], bytes: [0x1b, 0x46]),
        KeyEncodingCase("alt+control+x", .character("x"), [.alt, .control], bytes: [0x1b, 0x18]),
        KeyEncodingCase(
            "alt+f as eight-bit meta", .character("f"), .alt, mode: InputModes.eightBitMeta, bytes: [0xe6]),
        KeyEncodingCase(
            "eight-bit meta falls back to the prefix for multibyte",
            .character("é"),
            .alt,
            mode: InputModes.eightBitMeta,
            bytes: [0x1b, 0xc3, 0xa9]
        ),
    ]
}
