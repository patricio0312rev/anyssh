public struct PastePayload: Hashable, Sendable {
    private static let endMarker: [UInt8] = [
        ControlByte.escape, ControlByte.bracket, UInt8(ascii: "2"), UInt8(ascii: "0"),
        UInt8(ascii: "1"), ControlByte.tilde,
    ]
    private static let startMarker: [UInt8] = [
        ControlByte.escape, ControlByte.bracket, UInt8(ascii: "2"), UInt8(ascii: "0"),
        UInt8(ascii: "0"), ControlByte.tilde,
    ]

    public let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var lineCount: Int {
        guard !text.isEmpty else { return 0 }
        var count = 1
        var previousWasReturn = false
        for scalar in text.unicodeScalars {
            let isBreak = scalar == "\n" || scalar == "\r"
            if isBreak, !(previousWasReturn && scalar == "\n") { count += 1 }
            previousWasReturn = scalar == "\r"
        }
        return endsWithLineBreak ? count - 1 : count
    }

    public var isMultiline: Bool {
        lineCount > 1
    }

    public var endsWithLineBreak: Bool {
        text.unicodeScalars.last == "\n" || text.unicodeScalars.last == "\r"
    }

    public func bytes(mode: TerminalInputMode) -> [UInt8] {
        let body = normalised(Array(text.utf8), filtered: mode.bracketedPaste)
        guard mode.bracketedPaste else { return body }
        return Self.startMarker + body + Self.endMarker
    }

    private func normalised(_ source: [UInt8], filtered: Bool) -> [UInt8] {
        var output = [UInt8]()
        output.reserveCapacity(source.count)
        var index = source.startIndex

        while index < source.endIndex {
            if filtered, source[index...].starts(with: Self.endMarker) {
                index += Self.endMarker.count
                continue
            }
            let byte = source[index]
            index += 1
            guard byte == ControlByte.carriageReturn || byte == ControlByte.lineFeed else {
                output.append(byte)
                continue
            }
            let followsWithLineFeed = index < source.endIndex && source[index] == ControlByte.lineFeed
            if byte == ControlByte.carriageReturn, followsWithLineFeed {
                index += 1
            }
            output.append(ControlByte.carriageReturn)
        }
        return output
    }
}
