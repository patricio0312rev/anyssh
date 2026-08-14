import Foundation

public struct ClaudeHistoryParser: Sendable {
    public init() {}

    public func parse(_ bytes: Data) -> [RecentDirectorySighting] {
        guard let text = String(data: bytes, encoding: .utf8) else { return [] }
        var sightings = [RecentDirectorySighting]()
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.isEmpty { continue }
            if let sighting = parseHistoryLine(String(line)) {
                sightings.append(sighting)
                continue
            }
            if let sighting = parseProjectsLine(String(line)) {
                sightings.append(sighting)
            }
        }
        return sightings
    }

    private func parseHistoryLine(_ line: String) -> RecentDirectorySighting? {
        guard let object = object(line) else { return nil }
        guard let project = object["project"] as? String, project.hasPrefix("/") else { return nil }
        guard let timestamp = milliseconds(object["timestamp"]) else { return nil }
        return RecentDirectorySighting(
            path: project,
            source: .claude,
            lastUsed: Date(timeIntervalSince1970: timestamp / 1000)
        )
    }

    private func parseProjectsLine(_ line: String) -> RecentDirectorySighting? {
        let payload: String
        let stamp: TimeInterval?
        if let tab = line.firstIndex(of: "\t") {
            stamp = Double(line[..<tab]).map { $0 / 1000 }
            payload = String(line[line.index(after: tab)...])
        } else {
            stamp = nil
            payload = line
        }
        guard let object = object(payload) else { return nil }
        guard let cwd = object["cwd"] as? String, cwd.hasPrefix("/") else { return nil }
        let seconds = stamp ?? 0
        return RecentDirectorySighting(
            path: cwd,
            source: .claude,
            lastUsed: Date(timeIntervalSince1970: seconds)
        )
    }

    private func object(_ line: String) -> [String: Any]? {
        guard let data = line.data(using: .utf8),
            let root = try? JSONSerialization.jsonObject(with: data),
            let object = root as? [String: Any]
        else { return nil }
        return object
    }

    private func milliseconds(_ value: Any?) -> Double? {
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
