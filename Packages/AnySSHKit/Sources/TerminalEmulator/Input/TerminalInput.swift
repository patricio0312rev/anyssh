public struct TerminalInput: Hashable, Sendable {
    public var mode: TerminalInputMode
    public private(set) var latch = ModifierLatch()

    public init(mode: TerminalInputMode = TerminalInputMode()) {
        self.mode = mode
    }

    public var encoder: KeyEncoder {
        KeyEncoder(mode: mode)
    }

    public var preview: String {
        latch.pending.labelPrefix
    }

    @discardableResult
    public mutating func tap(_ modifier: LatchedModifier) -> ModifierLatch.State {
        latch.tap(modifier)
    }

    public mutating func clearLatch() {
        latch.clear()
    }

    public mutating func send(_ key: TerminalKey, modifiers: KeyModifiers = []) -> [UInt8] {
        encoder.encode(key, modifiers: modifiers.union(latch.consume()))
    }

    public mutating func send(_ chord: Chord) -> [UInt8] {
        let latched = latch.consume()
        guard var first = chord.steps.first else { return [] }
        first.modifiers.formUnion(latched)
        return encoder.encode(Chord([first] + chord.steps.dropFirst()))
    }

    public func send(_ paste: PastePayload) -> [UInt8] {
        encoder.encode(paste)
    }
}
