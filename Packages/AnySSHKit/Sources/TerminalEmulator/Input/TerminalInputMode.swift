public enum AltEncoding: Hashable, Sendable {
    case escapePrefix
    case eighthBit
}

public struct TerminalInputMode: Hashable, Sendable {
    public var applicationCursor: Bool
    public var bracketedPaste: Bool
    public var altEncoding: AltEncoding
    public var backspaceSendsControlH: Bool
    public var newlineMode: Bool

    public init(
        applicationCursor: Bool = false,
        bracketedPaste: Bool = false,
        altEncoding: AltEncoding = .escapePrefix,
        backspaceSendsControlH: Bool = false,
        newlineMode: Bool = false
    ) {
        self.applicationCursor = applicationCursor
        self.bracketedPaste = bracketedPaste
        self.altEncoding = altEncoding
        self.backspaceSendsControlH = backspaceSendsControlH
        self.newlineMode = newlineMode
    }
}
