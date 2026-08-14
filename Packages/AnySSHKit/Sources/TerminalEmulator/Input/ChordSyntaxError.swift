public enum ChordSyntaxError: Error, Hashable, Sendable {
    case emptyChord
    case danglingModifier(token: String)
    case unknownModifier(token: String, modifier: String)
    case unknownKey(token: String, key: String)
    case duplicateModifier(token: String, modifier: String)
}
