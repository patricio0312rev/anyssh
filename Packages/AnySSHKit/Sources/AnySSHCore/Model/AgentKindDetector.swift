public struct AgentKindDetector: Sendable {
    public init() {}

    public func detect(
        herdrKind: String? = nil, multiplexerTitle: String? = nil, terminalTitle: String? = nil
    ) -> AgentKind? {
        detect(signals: [herdrKind, multiplexerTitle, terminalTitle].compactMap { $0 })
    }

    public func detect(processNames: [String]) -> AgentKind? {
        AgentKindCatalog.kinds.first { kind in
            !kind.isMultiplexer && processNames.contains { name in matches(kind, name) }
        }
    }

    public func detect(signals: [String]) -> AgentKind? {
        signals.lazy.compactMap { match($0) }.compactMap(preferred).first
    }

    private func preferred(_ kind: AgentKind?) -> AgentKind? {
        guard let kind, !kind.isMultiplexer else { return nil }
        return kind
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
