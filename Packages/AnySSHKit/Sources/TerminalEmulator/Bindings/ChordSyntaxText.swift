extension KeyModifiers {
    public var syntaxPrefix: String {
        var prefix = ""
        if contains(.control) { prefix += "C-" }
        if contains(.alt) { prefix += "M-" }
        if contains(.shift) { prefix += "S-" }
        return prefix
    }
}

extension KeyStroke {
    public var syntaxText: String {
        modifiers.syntaxPrefix + key.name
    }
}

extension Chord {
    public var syntaxText: String {
        steps.map(\.syntaxText).joined(separator: ", ")
    }
}
