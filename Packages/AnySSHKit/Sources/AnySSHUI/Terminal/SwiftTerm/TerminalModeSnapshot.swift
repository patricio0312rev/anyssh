public nonisolated struct TerminalModeSnapshot: Hashable, Sendable {
    public let applicationCursor: Bool
    public let alternateBuffer: Bool
    public let mouseReporting: Bool

    public init(applicationCursor: Bool, alternateBuffer: Bool, mouseReporting: Bool) {
        self.applicationCursor = applicationCursor
        self.alternateBuffer = alternateBuffer
        self.mouseReporting = mouseReporting
    }
}
