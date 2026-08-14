import Foundation

public struct OpenCodeProjectParser: Sendable {
    public init() {}

    public func parse(_ bytes: Data) -> [RecentDirectorySighting] {
        guard let text = String(data: bytes, encoding: .utf8) else { return [] }
        var sightings = [RecentDirectorySighting]()
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            let value = String(line)
            if let sighting = parseRow(value) ?? parseJSON(value) {
                sightings.append(sighting)
            }
        }
        return sightings
    }

    private func parseRow(_ line: String) -> RecentDirectorySighting? {
        let separators: [Character] = ["|", "\t"]
        for separator in separators {
            guard let index = line.firstIndex(of: separator) else { continue }
            let path = String(line[..<index])
            let stamp = String(line[line.index(after: index)...])
            guard path.hasPrefix("/"), let ms = Double(stamp) else { continue }
            return RecentDirectorySighting(
                path: path,
                source: .opencode,
                lastUsed: Date(timeIntervalSince1970: ms / 1000)
            )
        }
        return nil
    }

    private func parseJSON(_ line: String) -> RecentDirectorySighting? {
        guard let data = line.data(using: .utf8),
            let root = try? JSONSerialization.jsonObject(with: data),
            let object = root as? [String: Any]
        else { return nil }
        guard let worktree = object["worktree"] as? String, worktree.hasPrefix("/") else {
            return nil
        }
        let ms: Double
        if let time = object["time"] as? [String: Any], let updated = number(time["updated"]) {
            ms = updated
        } else if let updated = number(object["time_updated"]) {
            ms = updated
        } else {
            ms = 0
        }
        return RecentDirectorySighting(
            path: worktree,
            source: .opencode,
            lastUsed: Date(timeIntervalSince1970: ms / 1000)
        )
    }

    private func number(_ value: Any?) -> Double? {
        switch value {
        case let number as NSNumber:
            return number.doubleValue
        case let text as String:
            return Double(text)
        default:
            return nil
        }
    }
}
