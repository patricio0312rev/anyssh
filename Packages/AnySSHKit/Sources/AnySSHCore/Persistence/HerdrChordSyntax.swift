enum HerdrChordSyntax {
    static func expanding(_ chord: String, prefix: String) -> String {
        let normalizedPrefix = phase23(prefix)
        let parts = splitPlus(chord)
        guard let first = parts.first, first.lowercased() == "prefix" else {
            return phase23(chord)
        }
        let rest = parts.dropFirst()
        guard !rest.isEmpty else { return normalizedPrefix }
        return normalizedPrefix + ", " + phase23(rest.joined(separator: "+"))
    }

    static func phase23(_ combo: String) -> String {
        let trimmed = combo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        guard trimmed.contains("+") else { return trimmed }

        let parts = splitPlus(trimmed)
        guard let key = parts.last else { return trimmed }

        var modifiers = ""
        for part in parts.dropLast() {
            switch part.lowercased() {
            case "c", "ctrl", "control":
                modifiers += "C-"
            case "m", "meta", "a", "alt", "opt", "option":
                modifiers += "M-"
            case "s", "shift":
                modifiers += "S-"
            default:
                break
            }
        }
        return modifiers + key
    }

    private static func splitPlus(_ text: String) -> [String] {
        text.split(separator: "+", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
