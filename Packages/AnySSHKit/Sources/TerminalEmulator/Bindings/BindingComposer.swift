public enum BindingComposer {
    public static func parse(modifier: KeyModifiers, text: String) -> SimpleBinding? {
        if modifier.isEmpty {
            if let chord = try? Chord(parsing: text) { return .chord(chord) }
            guard !text.isEmpty else { return nil }
            return .text(text)
        }
        return try? SimpleBindingParser.parse(modifier: modifier, text: text)
    }

    public static func preview(modifier: KeyModifiers, text: String) -> String? {
        parse(modifier: modifier, text: text)?.preview
    }

    public static func error(modifier: KeyModifiers, text: String) -> SimpleBindingSyntaxError? {
        guard !modifier.isEmpty else { return nil }
        do {
            _ = try SimpleBindingParser.parse(modifier: modifier, text: text)
            return nil
        } catch {
            return error
        }
    }
}
