import Foundation

public struct CodexRolloutParser: Sendable {
    public init() {}

    public func parse(_ bytes: Data) -> [RecentDirectorySighting] {
        guard let text = String(data: bytes, encoding: .utf8) else { return [] }
        var sightings = [RecentDirectorySighting]()
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            if let sighting = parseLine(String(line)) {
                sightings.append(sighting)
            }
        }
        return sightings
    }

    private func parseLine(_ line: String) -> RecentDirectorySighting? {
        guard let data = line.data(using: .utf8),
            let root = try? JSONSerialization.jsonObject(with: data),
            let object = root as? [String: Any]
        else { return nil }
        guard let payload = object["payload"] as? [String: Any] else { return nil }
        guard let cwd = payload["cwd"] as? String, cwd.hasPrefix("/") else { return nil }
        let lastUsed = date(from: object["timestamp"]) ?? .distantPast
        return RecentDirectorySighting(path: cwd, source: .codex, lastUsed: lastUsed)
    }

    private func date(from value: Any?) -> Date? {
        guard let text = value as? String else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: text) { return date }
        let basic = ISO8601DateFormatter()
        basic.formatOptions = [.withInternetDateTime]
        return basic.date(from: text)
    }
}
