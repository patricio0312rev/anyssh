public struct KeyModifiers: OptionSet, Hashable, Sendable {
    public static let control = KeyModifiers(rawValue: 1 << 0)
    public static let alt = KeyModifiers(rawValue: 1 << 1)
    public static let shift = KeyModifiers(rawValue: 1 << 2)

    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    var xtermParameter: Int? {
        guard !isEmpty else { return nil }
        var parameter = 1
        if contains(.shift) { parameter += 1 }
        if contains(.alt) { parameter += 2 }
        if contains(.control) { parameter += 4 }
        return parameter
    }
}
