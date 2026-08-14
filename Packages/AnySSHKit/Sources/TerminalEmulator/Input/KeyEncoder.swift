public struct KeyEncoder: Hashable, Sendable {
    public var mode: TerminalInputMode

    public init(mode: TerminalInputMode = TerminalInputMode()) {
        self.mode = mode
    }

    public func encode(_ key: TerminalKey, modifiers: KeyModifiers = []) -> [UInt8] {
        guard case .character(let character) = key else {
            return FunctionalKeySequence.bytes(for: key, modifiers: modifiers, mode: mode) ?? []
        }
        return encode(character: character, modifiers: modifiers)
    }

    public func encode(_ stroke: KeyStroke) -> [UInt8] {
        encode(stroke.key, modifiers: stroke.modifiers)
    }

    public func encode(_ chord: Chord) -> [UInt8] {
        chord.steps.flatMap(encode)
    }

    public func encode(_ paste: PastePayload) -> [UInt8] {
        paste.bytes(mode: mode)
    }

    private func encode(character: Character, modifiers: KeyModifiers) -> [UInt8] {
        let text = modifiers.contains(.shift) ? String(character).uppercased() : String(character)
        var body = Array(text.utf8)
        if modifiers.contains(.control), let code = ControlCharacters.code(for: character) {
            body = [code]
        }
        guard modifiers.contains(.alt) else { return body }
        return AltEncoder.apply(mode.altEncoding, to: body)
    }
}
