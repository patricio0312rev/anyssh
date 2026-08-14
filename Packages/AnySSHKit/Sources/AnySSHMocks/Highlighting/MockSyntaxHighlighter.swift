import AnySSHCore

public struct MockSyntaxHighlighter: SyntaxHighlighter {
    public static let defaultKeywords: Set<String> = [
        "class", "const", "def", "else", "enum", "export", "func", "function", "guard", "if",
        "import", "let", "package", "return", "struct", "type", "var",
    ]

    private let keywords: Set<String>

    public init(keywords: Set<String> = MockSyntaxHighlighter.defaultKeywords) {
        self.keywords = keywords
    }

    public func tokens(for blob: String, language: LanguageID) async -> [LineTokens] {
        blob.split(separator: "\n", omittingEmptySubsequences: false)
            .dropLast(blob.hasSuffix("\n") ? 1 : 0)
            .map { LineTokens(spans: spans(in: Array($0.utf16))) }
    }

    private func spans(in units: [UInt16]) -> [TokenSpan] {
        if let comment = commentSpan(in: units) { return [comment] }

        var spans: [TokenSpan] = []
        var offset = 0
        while offset < units.count {
            let unit = units[offset]
            if unit == code("\"") {
                let end = closingQuote(in: units, from: offset)
                spans.append(TokenSpan(range: offset..<end, scope: .string))
                offset = end
            } else if Self.isDigit(unit) {
                let end = run(in: units, from: offset, while: Self.isNumeric)
                spans.append(TokenSpan(range: offset..<end, scope: .number))
                offset = end
            } else if Self.isWordStart(unit) {
                let end = run(in: units, from: offset, while: Self.isWord)
                let word = String(decoding: units[offset..<end], as: UTF16.self)
                if keywords.contains(word) {
                    spans.append(TokenSpan(range: offset..<end, scope: .keyword))
                }
                offset = end
            } else {
                offset += 1
            }
        }
        return spans
    }

    private func commentSpan(in units: [UInt16]) -> TokenSpan? {
        var start = 0
        while start < units.count, units[start] == code(" ") { start += 1 }
        guard start < units.count else { return nil }
        let isHash = units[start] == code("#")
        let isSlashes =
            units[start] == code("/") && start + 1 < units.count
            && units[start + 1] == code("/")
        guard isHash || isSlashes else { return nil }
        return TokenSpan(range: start..<units.count, scope: .comment)
    }

    private func closingQuote(in units: [UInt16], from start: Int) -> Int {
        var offset = start + 1
        while offset < units.count {
            if units[offset] == code("\"") { return offset + 1 }
            offset += 1
        }
        return units.count
    }

    private func run(in units: [UInt16], from start: Int, while test: (UInt16) -> Bool) -> Int {
        var offset = start
        while offset < units.count, test(units[offset]) { offset += 1 }
        return offset
    }

    private static func isDigit(_ unit: UInt16) -> Bool {
        unit >= code("0") && unit <= code("9")
    }

    private static func isNumeric(_ unit: UInt16) -> Bool {
        isDigit(unit) || unit == code(".") || unit == code("_")
    }

    private static func isWordStart(_ unit: UInt16) -> Bool {
        let lower = unit >= code("a") && unit <= code("z")
        let upper = unit >= code("A") && unit <= code("Z")
        return lower || upper || unit == code("_")
    }

    private static func isWord(_ unit: UInt16) -> Bool {
        isWordStart(unit) || isDigit(unit)
    }
}

private func code(_ scalar: Unicode.Scalar) -> UInt16 {
    UInt16(scalar.value)
}
