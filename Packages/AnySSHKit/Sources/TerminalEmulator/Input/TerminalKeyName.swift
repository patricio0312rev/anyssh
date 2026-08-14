extension TerminalKey {
    private struct Name {
        let canonical: String
        let aliases: [String]
        let key: TerminalKey
    }

    private static let names: [Name] = [
        Name(canonical: "Esc", aliases: ["esc", "escape"], key: .escape),
        Name(canonical: "Enter", aliases: ["enter", "return", "cr"], key: .enter),
        Name(canonical: "Tab", aliases: ["tab"], key: .tab),
        Name(canonical: "Bksp", aliases: ["bksp", "backspace"], key: .backspace),
        Name(canonical: "Del", aliases: ["del", "delete"], key: .delete),
        Name(canonical: "Ins", aliases: ["ins", "insert"], key: .insert),
        Name(canonical: "Up", aliases: ["up"], key: .up),
        Name(canonical: "Down", aliases: ["down"], key: .down),
        Name(canonical: "Left", aliases: ["left"], key: .left),
        Name(canonical: "Right", aliases: ["right"], key: .right),
        Name(canonical: "Home", aliases: ["home"], key: .home),
        Name(canonical: "End", aliases: ["end"], key: .end),
        Name(canonical: "PgUp", aliases: ["pgup", "pageup"], key: .pageUp),
        Name(canonical: "PgDn", aliases: ["pgdn", "pgdown", "pagedown"], key: .pageDown),
        Name(canonical: "Space", aliases: ["space", "spc"], key: .character(" ")),
        Name(canonical: "Comma", aliases: ["comma"], key: .character(",")),
        Name(canonical: "Minus", aliases: ["minus", "dash", "hyphen"], key: .character("-")),
    ]

    public var name: String {
        if case .function(let number) = self { return "F\(number)" }
        if let match = Self.names.first(where: { $0.key == self }) { return match.canonical }
        guard case .character(let character) = self else { return "" }
        return String(character)
    }

    public init?(name: String) {
        let lowered = name.lowercased()
        if let match = Self.names.first(where: { $0.aliases.contains(lowered) }) {
            self = match.key
            return
        }
        if lowered.hasPrefix("f"), let number = Int(lowered.dropFirst()), (1...12).contains(number) {
            self = .function(number)
            return
        }
        guard name.count == 1, let character = name.first else { return nil }
        self = .character(character)
    }
}
