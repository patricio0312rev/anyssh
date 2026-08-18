public struct TerminalClickArbiter: Hashable, Sendable {
    private var spent = false

    public init() {}

    public mutating func touchBegan() {
        spent = false
    }

    public mutating func panBegan() {
        spent = false
    }

    public mutating func panEnded(travelled: Bool) -> Bool {
        guard !travelled else {
            spent = true
            return false
        }
        return claim()
    }

    public mutating func tapEnded() -> Bool {
        claim()
    }

    private mutating func claim() -> Bool {
        guard !spent else { return false }
        spent = true
        return true
    }
}
