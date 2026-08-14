import Foundation

public enum RecentDirectoriesParseError: Error, Hashable, Sendable {
    case invalidUTF8
    case invalidHeader
    case invalidField(String)
}

public struct RecentDirectoriesParser: Sendable {
    public init() {}

    public func parse(_ bytes: Data, limit: Int = 40) throws -> [RecentDirectory] {
        let sightings = try parseSightings(bytes)
        return RecentDirectoriesMerger.merge(sightings, limit: limit)
    }

    public func parseSightings(_ bytes: Data) throws -> [RecentDirectorySighting] {
        guard let text = String(data: bytes, encoding: .utf8) else {
            throw RecentDirectoriesParseError.invalidUTF8
        }
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        if lines.last == "" { lines.removeLast() }
        guard let header = lines.first,
            header == RecentDirectoriesCommand.protocolVersion
        else {
            throw RecentDirectoriesParseError.invalidHeader
        }
        var sightings = [RecentDirectorySighting]()
        for line in lines.dropFirst() where !line.isEmpty {
            let parts = line.split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false)
            guard parts.count == 3 else {
                throw RecentDirectoriesParseError.invalidField(String(line))
            }
            guard let source = AgentSource(rawValue: String(parts[0])) else {
                throw RecentDirectoriesParseError.invalidField(String(parts[0]))
            }
            guard let ms = Double(parts[1]) else {
                throw RecentDirectoriesParseError.invalidField(String(parts[1]))
            }
            let path = String(parts[2])
            guard path.hasPrefix("/") else {
                throw RecentDirectoriesParseError.invalidField(path)
            }
            sightings.append(
                RecentDirectorySighting(
                    path: path,
                    source: source,
                    lastUsed: Date(timeIntervalSince1970: ms / 1000)
                )
            )
        }
        return sightings
    }
}
