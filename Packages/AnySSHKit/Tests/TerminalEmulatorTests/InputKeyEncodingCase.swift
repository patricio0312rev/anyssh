@testable import TerminalEmulator

struct KeyEncodingCase: Sendable, CustomStringConvertible {
    let name: String
    let key: TerminalKey
    let modifiers: KeyModifiers
    let mode: TerminalInputMode
    let expected: [UInt8]

    init(
        _ name: String,
        _ key: TerminalKey,
        _ modifiers: KeyModifiers = [],
        mode: TerminalInputMode = TerminalInputMode(),
        bytes expected: [UInt8]
    ) {
        self.name = name
        self.key = key
        self.modifiers = modifiers
        self.mode = mode
        self.expected = expected
    }

    var description: String {
        name
    }
}

enum InputModes {
    static let normal = TerminalInputMode()
    static let application = TerminalInputMode(applicationCursor: true)
    static let eightBitMeta = TerminalInputMode(altEncoding: .eighthBit)
    static let controlH = TerminalInputMode(backspaceSendsControlH: true)
    static let newline = TerminalInputMode(newlineMode: true)
    static let bracketing = TerminalInputMode(bracketedPaste: true)
}

func inputEscape(_ tail: String) -> [UInt8] {
    [0x1b] + Array(tail.utf8)
}

enum InputEncodingTable {
    static let all = InputCharacterTable.rows + InputFunctionalTable.rows
}
