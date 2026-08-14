import AnySSHCore

public actor TreeSitterHighlighter: SyntaxHighlighter {
    private let workers: [HighlightWorker]
    private var cache: TokenCache
    private var inFlight: [String: Task<[LineTokens], Never>] = [:]
    private var nextWorker = 0

    private(set) var parseCount = 0

    public init(workerCount: Int = 2, cacheSpanLimit: Int = 400_000) {
        self.workers = (0..<max(1, workerCount)).map { _ in HighlightWorker() }
        self.cache = TokenCache(spanLimit: cacheSpanLimit)
    }

    public func tokens(for blob: String, language: LanguageID) async -> [LineTokens] {
        await parse(blob, language: language)
    }

    public func tokens(for blob: String, language: LanguageID, blobSha: String) async
        -> [LineTokens]
    {
        if let hit = cache.value(for: blobSha) { return hit }
        if let running = inFlight[blobSha] { return await running.value }

        let task = Task { await self.parse(blob, language: language) }
        inFlight[blobSha] = task
        let tokens = await task.value
        inFlight[blobSha] = nil
        cache.insert(tokens, for: blobSha)
        return tokens
    }

    func parse(_ blob: String, language: LanguageID) async -> [LineTokens] {
        guard let grammar = TreeSitterGrammar(language) else {
            return Array(repeating: LineTokens(spans: []), count: LineIndex(blob).lineCount)
        }

        parseCount += 1
        let worker = workers[nextWorker % workers.count]
        nextWorker = (nextWorker + 1) % workers.count
        return await worker.tokens(for: blob, grammar: grammar)
    }
}
