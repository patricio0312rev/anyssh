public struct KeyStroke: Hashable, Sendable {
    public var key: TerminalKey
    public var modifiers: KeyModifiers

    public init(_ key: TerminalKey, _ modifiers: KeyModifiers = []) {
        self.key = key
        self.modifiers = modifiers
    }
}
