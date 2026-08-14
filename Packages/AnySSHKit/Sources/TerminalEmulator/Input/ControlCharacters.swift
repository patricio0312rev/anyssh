enum ControlByte {
    static let escape: UInt8 = 0x1b
    static let bracket = UInt8(ascii: "[")
    static let ss3 = UInt8(ascii: "O")
    static let tilde = UInt8(ascii: "~")
    static let semicolon = UInt8(ascii: ";")
    static let horizontalTab: UInt8 = 0x09
    static let lineFeed: UInt8 = 0x0a
    static let carriageReturn: UInt8 = 0x0d
    static let backspace: UInt8 = 0x08
    static let delete: UInt8 = 0x7f
}

enum ControlCharacters {
    static func code(for character: Character) -> UInt8? {
        guard let ascii = character.asciiValue else { return nil }
        let lowered = (0x41...0x5a).contains(ascii) ? ascii + 0x20 : ascii

        switch lowered {
        case UInt8(ascii: "a")...UInt8(ascii: "z"):
            return lowered - 0x60
        case UInt8(ascii: " "), UInt8(ascii: "@"), UInt8(ascii: "2"):
            return 0x00
        case UInt8(ascii: "3"), UInt8(ascii: "["):
            return 0x1b
        case UInt8(ascii: "4"), UInt8(ascii: "\\"):
            return 0x1c
        case UInt8(ascii: "5"), UInt8(ascii: "]"):
            return 0x1d
        case UInt8(ascii: "6"), UInt8(ascii: "^"), UInt8(ascii: "~"):
            return 0x1e
        case UInt8(ascii: "7"), UInt8(ascii: "_"), UInt8(ascii: "/"):
            return 0x1f
        case UInt8(ascii: "8"), UInt8(ascii: "?"):
            return ControlByte.delete
        default:
            return nil
        }
    }
}

enum AltEncoder {
    static func apply(_ encoding: AltEncoding, to body: [UInt8]) -> [UInt8] {
        guard encoding == .eighthBit, body.count == 1, let only = body.first, only < 0x80 else {
            return [ControlByte.escape] + body
        }
        return [only | 0x80]
    }
}
