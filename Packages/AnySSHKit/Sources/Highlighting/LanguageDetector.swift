import AnySSHCore

extension LanguageID {
    public static let plainText = LanguageID(rawValue: "plaintext")
}

extension TreeSitterGrammar {
    public var id: LanguageID { LanguageID(rawValue: rawValue) }

    public init?(_ id: LanguageID) { self.init(rawValue: id.rawValue) }
}

public struct LanguageDetector: Sendable {
    private static let byExtension: [String: LanguageID] = [
        "swift": .swift,
        "ts": .typescript, "tsx": .typescript, "mts": .typescript, "cts": .typescript,
        "js": .javascript, "jsx": .javascript, "mjs": .javascript, "cjs": .javascript,
        "py": .python, "pyi": .python, "pyw": .python,
        "go": .go,
        "json": .json, "jsonc": .json,
        "yaml": .yaml, "yml": .yaml,
        "md": .markdown, "markdown": .markdown,
    ]

    private static let byInterpreter: [String: LanguageID] = [
        "python": .python, "python2": .python, "python3": .python,
        "node": .javascript, "nodejs": .javascript, "bun": .javascript, "deno": .javascript,
        "swift": .swift,
    ]

    public init() {}

    public func language(forPath path: String, firstLine: String? = nil) -> LanguageID {
        let name = path.split(separator: "/").last.map(String.init) ?? path
        if let dot = name.lastIndex(of: "."), dot != name.startIndex {
            let suffix = name[name.index(after: dot)...].lowercased()
            if let language = Self.byExtension[suffix] { return language }
        }
        if let firstLine, let language = Self.shebangLanguage(firstLine) { return language }
        return .plainText
    }

    private static func shebangLanguage(_ line: String) -> LanguageID? {
        guard line.hasPrefix("#!") else { return nil }
        let words = line.dropFirst(2).split(separator: " ", omittingEmptySubsequences: true)
        for word in words {
            let command = word.split(separator: "/").last.map(String.init) ?? String(word)
            if command == "env" { continue }
            if command.hasPrefix("-") { continue }
            return byInterpreter[command.lowercased()]
        }
        return nil
    }
}
