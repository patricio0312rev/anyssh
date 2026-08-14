public struct AgentKindDetector: Sendable {
    public init() {}

    public func detect(
        herdrKind: String? = nil, multiplexerTitle: String? = nil, terminalTitle: String? = nil
    ) -> AgentKind? {
        [herdrKind, multiplexerTitle, terminalTitle].compactMap { $0 }.lazy.compactMap(match).first
    }

    public func detect(processNames: [String]) -> AgentKind? {
        AgentKindCatalog.kinds.first { kind in
            processNames.contains { name in matches(kind, name) }
        }
    }

    private func match(_ signal: String) -> AgentKind? {
        let normalized = signal.lowercased()
        let words = normalized.split { character in
            character == " " || character == "-" || character == "/"
        }
        return AgentKindCatalog.kinds.first { kind in
            kind.aliases.contains { alias in normalized == alias || words.contains(Substring(alias)) }
        }
    }

    private func matches(_ kind: AgentKind, _ signal: String) -> Bool {
        let normalized = signal.lowercased()
        let words = normalized.split { $0 == " " || $0 == "-" || $0 == "/" }
        return kind.aliases.contains { alias in
            normalized == alias || words.contains(Substring(alias))
        }
    }
}
