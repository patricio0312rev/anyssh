import AnySSHCore

struct TokenCache {
    private var entries: [String: [LineTokens]] = [:]
    private var order: [String] = []
    private var spanCount = 0

    let spanLimit: Int

    init(spanLimit: Int) {
        self.spanLimit = spanLimit
    }

    var count: Int { entries.count }

    mutating func value(for key: String) -> [LineTokens]? {
        guard let hit = entries[key] else { return nil }
        touch(key)
        return hit
    }

    mutating func insert(_ tokens: [LineTokens], for key: String) {
        let cost = Self.cost(of: tokens)
        guard cost <= spanLimit else { return }

        if entries[key] != nil { remove(key) }
        entries[key] = tokens
        order.append(key)
        spanCount += cost

        while spanCount > spanLimit, let oldest = order.first {
            remove(oldest)
        }
    }

    private mutating func touch(_ key: String) {
        guard let position = order.firstIndex(of: key) else { return }
        order.remove(at: position)
        order.append(key)
    }

    private mutating func remove(_ key: String) {
        guard let tokens = entries.removeValue(forKey: key) else { return }
        spanCount -= Self.cost(of: tokens)
        if let position = order.firstIndex(of: key) { order.remove(at: position) }
    }

    static func cost(of tokens: [LineTokens]) -> Int {
        tokens.reduce(0) { $0 + $1.spans.count } + tokens.count
    }
}
