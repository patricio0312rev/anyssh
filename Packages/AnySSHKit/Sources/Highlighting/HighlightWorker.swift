import AnySSHCore

actor HighlightWorker {
    private var sessions: [TreeSitterGrammar: GrammarSession] = [:]

    private(set) var compiledGrammars = 0

    func tokens(for blob: String, grammar: TreeSitterGrammar) -> [LineTokens] {
        let index = LineIndex(blob)
        guard index.lineCount > 0 else { return [] }

        guard let session = session(for: grammar), let captures = session.captures(in: blob) else {
            return Array(repeating: LineTokens(spans: []), count: index.lineCount)
        }

        return TokenPainter(index: index).paint(captures)
    }

    private func session(for grammar: TreeSitterGrammar) -> GrammarSession? {
        if let existing = sessions[grammar] { return existing }
        guard let session = GrammarSession(grammar: grammar) else { return nil }
        sessions[grammar] = session
        compiledGrammars += 1
        return session
    }
}
