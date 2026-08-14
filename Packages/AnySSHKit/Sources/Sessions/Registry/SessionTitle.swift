import Foundation

public enum SessionTitle {
    public static let fallback = "Session"

    public static func sanitized(_ proposed: String) -> String? {
        let stripped = proposed.unicodeScalars
            .filter { !CharacterSet.controlCharacters.contains($0) && !isEmoji($0) }
        let trimmed = String(String.UnicodeScalarView(stripped))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func isEmoji(_ scalar: Unicode.Scalar) -> Bool {
        if scalar.value == 0xFE0F || scalar.value == 0x200D { return true }
        if scalar.properties.isEmojiPresentation || scalar.properties.isEmojiModifier { return true }
        return scalar.properties.isEmoji && scalar.value > 0x2100
    }

    public static func unique(_ proposed: String, among taken: some Sequence<String>) -> String {
        let base = sanitized(proposed) ?? fallback
        let existing = Set(taken)
        guard existing.contains(base) else { return base }
        var suffix = 2
        while existing.contains("\(base) \(suffix)") {
            suffix += 1
        }
        return "\(base) \(suffix)"
    }
}
