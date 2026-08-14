public enum MuxPrefix {
    public static let fallback = "C-b"

    public static func chordText(_ bindings: MuxKeyBindings?, fallback: String = fallback) -> String {
        guard let prefix = bindings?.prefix, !prefix.isEmpty else {
            return HerdrChordSyntax.phase23(fallback)
        }
        return HerdrChordSyntax.phase23(prefix)
    }
}
