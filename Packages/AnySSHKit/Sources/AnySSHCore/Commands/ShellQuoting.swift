public enum ShellQuoting {
    private static let inertCharacters = Set(
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/._-+,:@%"
    )

    public static func singleQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: #"'\''"#) + "'"
    }

    public static func quotedIfNeeded(_ value: String) -> String {
        guard !value.isEmpty, value.allSatisfy(inertCharacters.contains) else {
            return singleQuote(value)
        }
        return value
    }
}
