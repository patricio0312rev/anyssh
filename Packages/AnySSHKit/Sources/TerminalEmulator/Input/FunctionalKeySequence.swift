enum FunctionalKeySequence {
    static func bytes(for key: TerminalKey, modifiers: KeyModifiers, mode: TerminalInputMode) -> [UInt8]? {
        if let body = standalone(for: key, modifiers: modifiers, mode: mode) {
            guard modifiers.contains(.alt) else { return body }
            return AltEncoder.apply(mode.altEncoding, to: body)
        }
        guard let form = form(for: key) else { return nil }
        return sequence(form, modifiers: modifiers, mode: mode)
    }

    private static func standalone(
        for key: TerminalKey,
        modifiers: KeyModifiers,
        mode: TerminalInputMode
    ) -> [UInt8]? {
        switch key {
        case .enter:
            return mode.newlineMode
                ? [ControlByte.carriageReturn, ControlByte.lineFeed] : [ControlByte.carriageReturn]
        case .escape:
            return [ControlByte.escape]
        case .tab:
            guard modifiers.contains(.shift) else { return [ControlByte.horizontalTab] }
            return [ControlByte.escape, ControlByte.bracket, UInt8(ascii: "Z")]
        case .backspace:
            guard !modifiers.contains(.control) else { return [ControlByte.backspace] }
            return [mode.backspaceSendsControlH ? ControlByte.backspace : ControlByte.delete]
        default:
            return nil
        }
    }

    private enum Form {
        case cursor(UInt8)
        case ss3(UInt8)
        case tilde(Int)
    }

    private static func form(for key: TerminalKey) -> Form? {
        switch key {
        case .up: .cursor(UInt8(ascii: "A"))
        case .down: .cursor(UInt8(ascii: "B"))
        case .right: .cursor(UInt8(ascii: "C"))
        case .left: .cursor(UInt8(ascii: "D"))
        case .home: .cursor(UInt8(ascii: "H"))
        case .end: .cursor(UInt8(ascii: "F"))
        case .insert: .tilde(2)
        case .delete: .tilde(3)
        case .pageUp: .tilde(5)
        case .pageDown: .tilde(6)
        case .function(let number): functionForm(number)
        default: nil
        }
    }

    private static let tildeFunctionNumbers = [15, 17, 18, 19, 20, 21, 23, 24]

    private static func functionForm(_ number: Int) -> Form? {
        switch number {
        case 1...4:
            return .ss3(UInt8(ascii: "P") + UInt8(number - 1))
        case 5...12:
            return .tilde(tildeFunctionNumbers[number - 5])
        default:
            return nil
        }
    }

    private static func sequence(_ form: Form, modifiers: KeyModifiers, mode: TerminalInputMode) -> [UInt8] {
        let parameter = modifiers.xtermParameter

        switch form {
        case .cursor(let final), .ss3(let final):
            guard let parameter else {
                let useSS3 = if case .ss3 = form { true } else { mode.applicationCursor }
                return [ControlByte.escape, useSS3 ? ControlByte.ss3 : ControlByte.bracket, final]
            }
            return csi(digits(1) + [ControlByte.semicolon] + digits(parameter) + [final])
        case .tilde(let number):
            guard let parameter else { return csi(digits(number) + [ControlByte.tilde]) }
            return csi(
                digits(number) + [ControlByte.semicolon] + digits(parameter) + [ControlByte.tilde]
            )
        }
    }

    private static func csi(_ body: [UInt8]) -> [UInt8] {
        [ControlByte.escape, ControlByte.bracket] + body
    }

    private static func digits(_ value: Int) -> [UInt8] {
        Array(String(value).utf8)
    }
}
