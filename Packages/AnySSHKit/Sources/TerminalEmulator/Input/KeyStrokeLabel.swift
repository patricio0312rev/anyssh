extension KeyStroke {
    public var label: String {
        let name = key.name
        guard name.count == 1 else { return modifiers.labelPrefix + name }

        let cased = modifiers.isDisjoint(with: [.shift, .control]) ? name : name.uppercased()
        let controlled = modifiers.contains(.control) ? "^" + cased : cased
        return modifiers.contains(.alt) ? "M-" + controlled : controlled
    }
}

extension KeyModifiers {
    public var labelPrefix: String {
        var prefix = ""
        if contains(.alt) { prefix += "M-" }
        if contains(.control) { prefix += "^" }
        if contains(.shift) { prefix += "S-" }
        return prefix
    }
}
