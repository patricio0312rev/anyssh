import AnySSHCore
import Foundation

public enum HerdrParseError: Error, Hashable, Sendable {
    case notInstalled
    case malformedJSON
    case protocolMismatch(Int)
    case missingField(String)
}

public struct HerdrClientStatus: Hashable, Sendable {
    public let path: String
    public let version: String
    public let protocolVersion: Int
    public let binary: String

    public init(path: String, version: String, protocolVersion: Int, binary: String) {
        self.path = path
        self.version = version
        self.protocolVersion = protocolVersion
        self.binary = binary
    }
}

struct HerdrStatusParser: Sendable {
    func clientStatus(from text: String) throws -> HerdrClientStatus {
        if text.contains("herdr:not-installed") {
            throw HerdrParseError.notInstalled
        }
        var path = ""
        var jsonLines = [String]()
        for line in text.split(whereSeparator: \.isNewline).map(String.init) {
            if line.hasPrefix("path\t") {
                path = String(line.dropFirst(5))
            } else if !line.isEmpty {
                jsonLines.append(line)
            }
        }
        let object = try HerdrJSON.object(jsonLines.joined(separator: "\n"))
        guard let version = object["version"] as? String else {
            throw HerdrParseError.missingField("version")
        }
        guard let protocolVersion = HerdrJSON.int(object["protocol"]) else {
            throw HerdrParseError.missingField("protocol")
        }
        if protocolVersion != HerdrCommands.supportedProtocol {
            throw HerdrParseError.protocolMismatch(protocolVersion)
        }
        let binary = (object["binary"] as? String) ?? path
        let resolvedPath = path.isEmpty ? binary : path
        return HerdrClientStatus(
            path: resolvedPath,
            version: version,
            protocolVersion: protocolVersion,
            binary: binary
        )
    }

    func sessions(from text: String) throws -> [MuxSession] {
        let root = try HerdrJSON.object(text)
        let rows = (root["sessions"] as? [[String: Any]]) ?? []
        return rows.compactMap { row in
            guard let name = row["name"] as? String else { return nil }
            return MuxSession(
                id: MuxSessionID(rawValue: name),
                name: name,
                isAttached: HerdrJSON.bool(row["running"])
            )
        }
    }

    func paneText(from text: String) throws -> String {
        if let object = try? HerdrJSON.object(text) {
            if let result = object["result"] as? [String: Any] {
                if let read = result["read"] as? [String: Any],
                    let body = read["text"] as? String
                {
                    return body
                }
                if let body = result["text"] as? String { return body }
            }
            if let body = object["text"] as? String { return body }
        }
        return text
    }

    func keyBindings(from configText: String) -> MuxKeyBindings {
        var prefix = "ctrl+b"
        var chords = [String: String]()
        for rawLine in configText.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            guard let separator = line.firstIndex(of: "=") else { continue }
            let key = line[..<separator].trimmingCharacters(in: .whitespaces)
            var value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
            if value.hasPrefix("\"") && value.hasSuffix("\"") && value.count >= 2 {
                value = String(value.dropFirst().dropLast())
            }
            if key == "prefix" {
                prefix = value
            } else if key.hasPrefix("key.") {
                chords[String(key.dropFirst("key.".count))] = value
            } else if [
                "new_tab", "previous_tab", "next_tab", "zoom", "workspace_picker", "new_workspace",
                "detach",
            ].contains(key) {
                chords[key] = value
            }
        }
        return MuxKeyBindings(prefix: prefix, chords: chords)
    }
}

enum HerdrJSON {
    static func object(_ text: String) throws -> [String: Any] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw HerdrParseError.malformedJSON
        }
        return object
    }

    static func int(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        return nil
    }

    static func bool(_ value: Any?) -> Bool {
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value.boolValue }
        return false
    }
}
