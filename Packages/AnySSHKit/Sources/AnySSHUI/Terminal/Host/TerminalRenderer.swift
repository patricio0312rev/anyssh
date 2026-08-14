public nonisolated enum TerminalRenderer: String, Sendable, CaseIterable {
    case metal
    case coreText
}

public nonisolated enum TerminalBufferingMode: String, Sendable, CaseIterable {
    case perRowPersistent
    case perFrameAggregated
}
