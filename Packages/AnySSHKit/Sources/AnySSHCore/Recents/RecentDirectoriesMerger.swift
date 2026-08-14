import Foundation

public enum RecentDirectoriesMerger: Sendable {
    public static func merge(
        _ sightings: [RecentDirectorySighting],
        limit: Int = 40
    ) -> [RecentDirectory] {
        guard limit > 0 else { return [] }
        var byPath = [String: [RecentDirectorySighting]]()
        for sighting in sightings {
            let path = normalize(sighting.path)
            guard !path.isEmpty else { continue }
            byPath[path, default: []].append(
                RecentDirectorySighting(path: path, source: sighting.source, lastUsed: sighting.lastUsed)
            )
        }

        var merged = byPath.map { path, group -> RecentDirectory in
            let ordered = group.sorted { lhs, rhs in
                if lhs.lastUsed != rhs.lastUsed { return lhs.lastUsed > rhs.lastUsed }
                return lhs.source < rhs.source
            }
            var sources = [AgentSource]()
            var seen = Set<AgentSource>()
            for item in ordered where seen.insert(item.source).inserted {
                sources.append(item.source)
            }
            let lastUsed = ordered.map(\.lastUsed).max() ?? .distantPast
            return RecentDirectory(path: path, sources: sources, lastUsed: lastUsed)
        }

        merged.sort { lhs, rhs in
            if lhs.lastUsed != rhs.lastUsed { return lhs.lastUsed > rhs.lastUsed }
            return lhs.path < rhs.path
        }
        return Array(merged.prefix(limit))
    }

    private static func normalize(_ path: String) -> String {
        var value = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "" }
        while value.count > 1, value.hasSuffix("/") {
            value.removeLast()
        }
        if isNoise(value) { return "" }
        return value
    }

    private static func isNoise(_ path: String) -> Bool {
        switch path {
        case "/", "/tmp", "/var", "/private", "/private/tmp":
            return true
        default:
            return false
        }
    }
}
