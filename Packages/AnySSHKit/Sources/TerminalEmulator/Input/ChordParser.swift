enum ChordParser {
    static func steps(in text: String) throws(ChordSyntaxError) -> [KeyStroke] {
        let tokens = text.split(whereSeparator: { $0 == "," || $0.isWhitespace })
        guard !tokens.isEmpty else { throw ChordSyntaxError.emptyChord }
        return try tokens.map(stroke)
    }

    private static func stroke(in token: Substring) throws(ChordSyntaxError) -> KeyStroke {
        let parts = token.count == 1 ? [token] : token.split(separator: "-", omittingEmptySubsequences: false)
        guard var name = parts.last, !name.isEmpty else {
            throw ChordSyntaxError.danglingModifier(token: String(token))
        }

        var modifiers = KeyModifiers()
        if name.count > 1, name.hasPrefix("^") {
            modifiers.insert(.control)
            name = name.dropFirst()
        }
        guard let key = TerminalKey(name: String(name)) else {
            throw ChordSyntaxError.unknownKey(token: String(token), key: String(name))
        }

        for part in parts.dropLast() {
            let modifier = try self.modifier(part, in: token)
            guard !modifiers.contains(modifier) else {
                throw ChordSyntaxError.duplicateModifier(token: String(token), modifier: String(part))
            }
            modifiers.insert(modifier)
        }
        return KeyStroke(key, modifiers)
    }

    private static func modifier(_ part: Substring, in token: Substring) throws(ChordSyntaxError)
        -> KeyModifiers
    {
        switch part.lowercased() {
        case "c", "ctrl", "control":
            return .control
        case "s", "shift":
            return .shift
        case "m", "meta", "a", "alt", "opt", "option":
            return .alt
        default:
            throw ChordSyntaxError.unknownModifier(token: String(token), modifier: String(part))
        }
    }
}
