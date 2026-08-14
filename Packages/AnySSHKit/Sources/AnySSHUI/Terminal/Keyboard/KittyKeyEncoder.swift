import TerminalEmulator

enum KittyKeyEncoder {
    static func encode(
        key: TerminalKey,
        control: Bool,
        alt: Bool,
        shift: Bool,
        command: Bool
    ) -> [UInt8]? {
        guard command, let codepoint = codepoint(for: key) else { return nil }
        var mods = 1
        if shift { mods += 1 }
        if alt { mods += 2 }
        if control { mods += 4 }
        mods += 8
        let body = "\(codepoint);\(mods)u"
        return [ControlByte.escape, ControlByte.bracket] + Array(body.utf8)
    }

    private static func codepoint(for key: TerminalKey) -> Int? {
        switch key {
        case .character(let character):
            guard let scalar = character.unicodeScalars.first else { return nil }
            return Int(scalar.value)
        case .enter: return 13
        case .escape: return 27
        case .tab: return 9
        case .backspace: return 127
        default: return nil
        }
    }
}

private enum ControlByte {
    static let escape: UInt8 = 0x1b
    static let bracket = UInt8(ascii: "[")
}
